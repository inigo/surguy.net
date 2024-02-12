
---
title: Creating an "Absolute Singleton"
date: 2021-04-03T22:53:58+05:30
draft: false
author: Inigo Surguy
description: This document describes how to create an "Absolute Singleton" to pass data between identically named Java classes in different classloaders
#toc:
---

	


## Motivation


While I was writing the code to use BCEL to add trace printouts to Java, I briefly thought that I needed to have two copies of my logging class, one loaded by the original classloader and one loaded by my own classloader, and pass objects between them.
		
Actually, all I needed to do was to make sure that my classloader didn't load the logging class, so I didn't have any problems with class shadowing. However, before realising this, I wrote code to create an "Absolute Singleton" - a singleton of which only one instance exists across all classloaders.


## The problems

The obvious thing to do is to use the standard Java singleton idiom, and have a private constructor, and a public static getInstance method that either creates an instance, or returns the existing one. If it's called within the child classloader rather than the root classloader, it can call:

    class.getClassLoader().getParent().loadClass("className")
		
which will return a class object from the parent's classloader. The obvious next step is to use reflection to call the getInstance of this class, and pass back the object obtained.
		
The problem is that instances of the same class loaded in different classloaders can't be cast to each other. Nor can a class be cast to an interface in a different classloader. It is possible to use reflection to call methods on the object, but it's tedious to do this all the time.
		
The solution is to use the `java.lang.reflect.Proxy` class, which dynamically implements interfaces that you pass to it, in conjunction with the PassThroughProxyHandler defined below, which just passes calls to its methods to its delegate. By defining the singleton class to implement an interface, and accessing it via its interface rather than its class, the Proxy can be substituted for the singleton instance when it's accessed in the child classloader.
	

## The code
### The Singleton
		
    import java.lang.reflect.*;
    
    /**
     * There can be only one - ie. even if the class is loaded in several different classloaders,
     * there will be only one instance of the object.
     */
    public class AbsoluteSingleton implements SingletonInterface {
    
          /**
           *  This is effectively an instance of this class (although actually it may be instead a
           *  java.lang.reflect.Proxy wrapping an instance from the original classloader).
           */
          public static SingletonInterface instance = null;
          /**
           * Retrieve an instance of AbsoluteSingleton from the original classloader. This is a true
           * Singleton, in that there will only be one instance of this object in the virtual machine,
           * even though there may be several copies of its class file loaded in different classloaders.
           */
          public synchronized static SingletonInterface getInstance() {
              ClassLoader myClassLoader = AbsoluteSingleton.class.getClassLoader();
              if (instance==null) {
                  // The root classloader is sun.misc.Launcher package. If we are not in a sun package,
                  // we need to get hold of the instance of ourself from the class in the root classloader.
                  if (! myClassLoader.toString().startsWith("sun.")) {
                      try {
                          // So we find our parent classloader
                          ClassLoader parentClassLoader = AbsoluteSingleton.class.getClassLoader().getParent();
                          // And get the other version of our current class
                          Class otherClassInstance = parentClassLoader.loadClass(AbsoluteSingleton.class.getName());
                          // And call its getInstance method - this gives the correct instance of ourself
                          Method getInstanceMethod = otherClassInstance.getDeclaredMethod("getInstance", new Class[] { });
                          Object otherAbsoluteSingleton = getInstanceMethod.invoke(null, new Object[] { } );
                          // But, we can't cast it to our own interface directly because classes loaded from
                  // different classloaders implement different versions of an interface.
                  // So instead, we use java.lang.reflect.Proxy to wrap it in an object that *does*
                  // support our interface, and the proxy will use reflection to pass through all calls
                  // to the object.
                          instance = (SingletonInterface) Proxy.newProxyInstance(myClassLoader,
                                                               new Class[] { SingletonInterface.class },
                                                               new PassThroughProxyHandler(otherAbsoluteSingleton));
              // And catch the usual tedious set of reflection exceptions
                  // We're cheating here and just catching everything - don't do this in real code
                      } catch (Exception e) {
                          e.printStackTrace();
                      }
                  // We're in the root classloader, so the instance we have here is the correct one
                  } else {
                      instance = new AbsoluteSingleton();
                  }
              }
    
              return instance;
          }
    
          private AbsoluteSingleton() {
          }
    
          private String value = "";
          public String getValue() { return value; }
          public void setValue(String value) {
              this.value = value;
          }
    
    }

### The interface
		
    public interface SingletonInterface {
        String getValue();
        void setValue(String value);
    }    

### The InvocationHandler

    import java.lang.reflect.InvocationHandler;
    import java.lang.reflect.Method;
    
    
    /**
     * An invocation handler that passes on any calls made to it directly to its delegate.
     * This is useful to handle identical classes loaded in different classloaders - the
     * VM treats them as different classes, but they have identical signatures.
     * 
     * Note this is using class.getMethod, which will only work on public methods.
     */
    class PassThroughProxyHandler implements InvocationHandler {
          private final Object delegate;
          public PassThroughProxyHandler(Object delegate) {
              this.delegate = delegate;
          }
          public Object invoke(Object proxy, Method method, Object[] args)
                  throws Throwable {
              Method delegateMethod = delegate.getClass().getMethod(method.getName(), method.getParameterTypes());
              return delegateMethod.invoke(delegate, args);
          }
    }

## Download this code


[Download this code](/code/absolutesingleton.zip)


