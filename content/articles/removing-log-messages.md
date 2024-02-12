
---
title: Speeding up Log4J in Java 1.5
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: Logging in Java imposes a performance penalty, even when the log messages are not displayed. This article describes a method for completely removing that performance penalty for Log4J, using bytecode manipulation and Java 1.5's new instrumentation classes.
#toc:
---

    
	
	    
		
Logging in Java imposes a performance penalty, even when the log messages are not displayed. This article describes a method for completely removing that performance penalty for Log4J, using bytecode manipulation and Java 1.5's new instrumentation classes.
		    
	    




In Log4J, if you log a message at DEBUG level, and the current Appender is set to only log messages of INFO level and above, then the message will not be displayed. The performance penalty for calling the log method itself is minimal - a few nanoseconds. However, it may take longer to evaluate the arguments to the log method. For example:

    logger.debug("The large object is "+largeObject.toString());

Evaluating largeObject.toString() may be slow, and it is evaluated before the call to the logger, so the logger cannot prevent it being evaluated, even though it will not be used.



The standard way of preventing the unnecessary method evaluation is to wrap the call to the logger - for example:

    if (DEBUG) { logger.debug("The large object is "+largeObject.toString()); }

where the DEBUG variable is defined elsewhere to be `public static final boolean DEBUG = false`. Some compilers will not even add the logger call to the class's bytecode, because it is guaranteed never to occur.



The method recommended in the [Log4J FAQ](http://logging.apache.org/log4j/docs/FAQ.html#fastLogging) is:

    if(logger.isDebugEnabled()) {
     logger.debug("The large object is "+largeObject.toString());
    }

This will be very slightly slower, but has the major advantage that the log level can be changed at runtime, rather than requiring a recompile.



However, the drawback of both of these approaches (and of other ideas - such as using anonymous inner classes that are lazily evaluated only if displayed) is that they add additional syntax to the log call, making methods longer and less readable. It would be better if the log call could just be automatically removed if they're not being used.



## Solving these problems in JDK 1.5


It is possible to do this using bytecode manipulation - searching for and removing calls to the logger as the class is loaded. The new Java 1.5 instrumentation classes make this particularly easy, by allowing ClassTransformer classes to be registered on the command line that are allowed to manipulate class files as they are loaded.



The code to do this follows:

     
    package net.surguy.logfilter;
    
    import org.objectweb.asm.*;
    
    import java.lang.instrument.*;
    import java.lang.reflect.*;
    import java.security.ProtectionDomain;
    import java.util.ArrayList;
    import java.util.List;
    import java.util.Arrays;
        
    public class LogPreloader implements ClassFileTransformer {
    
        public static void premain(String options, Instrumentation instrumentation) {
            LogLevel highestLevelToRemove;
            try {
                highestLevelToRemove = (options == null) ? LogLevel.debug : LogLevel.valueOf(options);
            } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Option passed to "+
            "LogPreloader class transformer must be one of " 
            + Arrays.asList(LogLevel.values()));
            }
            instrumentation.addTransformer(new LogPreloader(highestLevelToRemove));
        }
    
        private final LogLevel highestLevelToRemove;
        private LogPreloader(LogLevel highestLevelToRemove) {
            this.highestLevelToRemove = highestLevelToRemove;
        }
    
        public byte[] transform(ClassLoader loader, String className, 
                Class classBeingRedefined, ProtectionDomain protectionDomain, 
                byte[] classfileBuffer) throws IllegalClassFormatException {
            // Returning null means that no transformation was done.
        if (isSystemClass(className) || (isLog4JClass(className))) { return null; }
        ClassReader reader = new ClassReader(classfileBuffer);
        // Make ASM write out the correct class file version (compatible with -target 1.5)
            final int majorVersion = 49;
            final int minorVersion = 0;
            ClassWriter writer = new ClassWriter(true, majorVersion, minorVersion);
            ClassVisitor adapter = new RemoveLoggingClassAdapter(writer, highestLevelToRemove);
            reader.accept(adapter, false);
            byte[] results = writer.toByteArray();
            return results;
        }
    
        private boolean isLog4JClass(String className) {
            return className.startsWith("org/apache/log4j");
        }
    
        private boolean isSystemClass(String className) {
        return ((className.startsWith("java/")) || (className.startsWith("javax/"))
            || (className.startsWith("sun/")));
        }
    }
    
    enum LogLevel { debug, info, warn, error, fatal };
    
    class RemoveLoggingClassAdapter extends ClassAdapter implements Constants {
        private final LogLevel highestLevelToRemove;
    
        public RemoveLoggingClassAdapter(ClassVisitor cv, LogLevel highestLevelToRemove) {
            super(cv);
            this.highestLevelToRemove = highestLevelToRemove;
        }
    
        public CodeVisitor visitMethod(int access, String name, String desc,
            String[] exceptions, Attribute attrs) {
            CodeVisitor methodVisitor = cv.visitMethod(access, name, desc, exceptions, attrs);
        CodeVisitor dynamicLogRemover = 
            (CodeVisitor) Proxy.newProxyInstance(this.getClass().getClassLoader(),
                    new Class[]{CodeVisitor.class}, 
            new DynamicLogRemovingHandler(methodVisitor, highestLevelToRemove));
            return methodVisitor == null ? null : dynamicLogRemover;
        }
    
        public void visitInnerClass(String name, String outerName, String innerName, int access) {
            super.visitInnerClass(name, outerName, innerName, access);    
        }
    }
    
    class DynamicLogRemovingHandler implements InvocationHandler {
    
        // Lazily created, because methods without calls to the logger 
        // (probably a high proportion) won't require it
        private List<Pair<Method,Object[]>> savedInstructions;
        private boolean isStoring = false;
        private final CodeVisitor codeVisitor;
        private final LogLevel highestLevelToRemove;
    
        public DynamicLogRemovingHandler(CodeVisitor methodVisitor, LogLevel highestLevelToRemove) {
            this.codeVisitor = methodVisitor;
            this.highestLevelToRemove = highestLevelToRemove;
        }
    
        /**
         * Most ASM calls will be passed through directly to the wrapped codeVisitor -
         */
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            if (method.getName().equals("visitFieldInsn")) {
                final Object accessedFieldClass = args[3];
                if ("Lorg/apache/log4j/Category;".equals(accessedFieldClass)) { isStoring = true; }
            } else if (method.getName().equals("visitMethodInsn")) {
                final Object calledObjectName = args[1];
                final String calledMethodName = (String) args[2];
                if (("org/apache/log4j/Category".equals(calledObjectName))) {
            if ((isLogMethod(calledMethodName)) && 
            (LogLevel.valueOf(calledMethodName).compareTo(highestLevelToRemove)<=0)) {
                        isStoring = false;
                        clearSavedInstructions();
                        return null;
                    } else {
                        isStoring = false;
                        replaySavedInstructions();
                        clearSavedInstructions();
                    }
                }
            } else if (method.getName().equals("visitMaxs")) {
                isStoring = false;
                replaySavedInstructions();
                clearSavedInstructions();
            }
    
            if (isStoring) {
                store(new Pair<Method, Object[]>(method, args));
            } else {
                method.invoke(codeVisitor, args);
            }
            return null;
        }
    
        private boolean isLogMethod(String methodName) {
            for (LogLevel level : LogLevel.values())
                if (level.toString().equals(methodName)) return true;
            return false;
        }
    
        private void replaySavedInstructions() 
            throws IllegalAccessException, InvocationTargetException {
            if (savedInstructions==null) { return; }
            for (Pair<Method, Object[]> instruction : savedInstructions) {
                instruction.item1.invoke(codeVisitor, instruction.item2);
            }
        }
    
        private void clearSavedInstructions() {
            if (savedInstructions!=null) { savedInstructions.clear(); }
        }
    
        private void store(Pair<Method, Object[]> methodToStore) {
        if (savedInstructions==null) { 
            savedInstructions = new ArrayList<Pair<Method,Object[]>>(); 
        }
            savedInstructions.add(methodToStore);
        }
    
    }
    
    class Pair<Item1, Item2> {
        final Item1 item1;
        final Item2 item2;
        public Pair(Item1 item1, Item2 item2) {
            this.item1 = item1;
            this.item2 = item2;
        }
    } 
        



The code uses several of the new language features in Java 1.5 - generics and enums, as well as the new Instrumentation classes. It will
not compile on Java 1.4 or earlier, and requires the "-source 1.5" option to compile under Java 1.5.



To use this code, launch Java with the arguments:

    java -javaagent:net.surguy.logfilter.LogPreloader=debug [your own class]

The argument is optional, and can be one of "debug", "info", "warn", "error" or "fatal", corresponding to the standard Log4J log levels.
 


## How does it work


As Java loads each class, it passes it to each of the registered ClassFileTransformers, which get a chance to alter its bytecode. The code above uses the [ASM bytecode manipulation library](http://asm.objectweb.org/) to do so. (I've previously used BCEL - the ByteCode Engineering Library - but I found ASM to be easier to use and faster).



A simple class that does logging, looking like this:
    
    import org.apache.log4j.Category;
    public class DoSomeLogging {
        private static final Category logger = Category.getInstance("DoSomeLogging");
        public void logNow() {
        logger.debug("This is a log message");
        }
    }

compiles to bytecode for the logNow method that looks something like:

    //    0    0:getstatic       #2   <Field Category logger>
    //    1    3:ldc1            #3   <String "This is a log message">
    //    2    5:invokevirtual   #4   <Method void Category.debug(Object)>
    //    3    8:return          

(this is actually the bytecode view of the [JAD decompiler](http://kpdus.tripod.com/jad.html)). 



As this bytecode is being loaded by the ClassTransformer, most of the JVM instructions are written straight out again to the ClassWriter. 
However, if it reaches a **GETSTATIC** instruction (in ASM, this is a call to the visitFieldInsn method), it checks to see whether it is
a reference to a Log4J Category. If so, then it starts storing JVM instructions rather than writing them out. 



JVM instructions are stored until an **INVOKEVIRTUAL** instruction is reached that is invoked on the Log4J Category object (this is a call
to visitMethodInsn in ASM), or the end of the method (a call to visitMaxs). If the **INVOKEVIRTUAL** is calling a log method that the
ClassFileTransformer has been instructed to ignore, then the stored instructions are discarded; otherwise, they are replayed to be
written out to the classfile.



The ASM CodeVisitor interface is implemented with a dynamic proxy. This is an appropriate idiom to use here because almost all
of the many CodeVisitor methods are treated in the same way - that is, they are passed straight through to the CodeWriter or
stored in the savedInstructions list. It is also much easier to store and replay a Method with its associated Object[] of arguments
than it is to store an individual object for each instruction that knows how to replay itself.



## Current shortcomings


The biggest limitation of the existing code is that there is no way of changing the log level at runtime. This should be possible to fix - the instrumentation classes do allow classes to be reloaded at runtime, but I haven't really looked into that yet.


The current log removal is less discriminating than Log4J's native categorization - it's not possible to allow DEBUG messages in just one package or class, for eample. It should be possible to hook into Log4J's existing mechanisms to check whether logging should be enabled for specific log categories.



## Downloading the log removal code

The log removal code and its sourcecode are Free Software - you can 
[download a zip of it here.](/code/logfilter.zip) (the zip also includes the ASM, JUnit and Log4J libraries,
which are covered by their own licenses).

It is covered by the [modified BSD license](http://www.gnu.org/licenses/info/BSD_3Clause.html).	

