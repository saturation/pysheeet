=======================
Python basic cheatsheet
=======================

.. contents:: Table of Contents
    :backlinks: none


Python Naming Rule
--------------------

.. code-block:: python

    # see: PEP 8

    # for class
    #
    # good:
    #   MyClass
    # bad:
    #   myClass, my_class
    MyClass

    # for func, module, package, variables
    #
    # good:
    #   var_underscore_separate
    # bad:
    #   varCamel, VarCamel
    var_underscore_separate

    # for public use
    var

    # for internal use
    _var

    # convention to avoid conflict keyword
    var_

    # for private use in class
    __var

    # for protect use in class
    _var_

    # "magic" method or attributes
    # ex: __init__, __file__, __main__
    __var__

    # for "internal" use throwaway variable
    # usually used in loop
    # ex: [_ for _ in range(10)]
    # or variable not used
    # for _, a in [(1,2),(3,4)]: print a
    _


Using ``__future__`` backport features
---------------------------------------

.. code-block:: python

    # PEP 236 - Back to the __future__

    # backport python3 print_function in python2

    >>> print "Hello World"  # print is a statement
    Hello World
    >>> from __future__ import print_function
    >>> print "Hello World"
      File "<stdin>", line 1
        print "Hello World"
                          ^
    SyntaxError: invalid syntax
    >>> print("Hello World") # print become a function
    Hello World

    # backport python3 unicode_literals in python2

    >>> type("Guido") # string type is str in python2
    <type 'str'>
    >>> from __future__ import unicode_literals
    >>> type("Guido") # string type become unicode
    <type 'unicode'>

    # backport PEP 238 -- Changing the Division Operator

    >>> 1/2
    0
    >>> from __future__ import division
    >>> 1/2   # return a float (classic division)
    0.5
    >>> 1//2  # return a int (floor division)
    0


.. note::

    ``from __future__ import feature`` is a `future statement`__.
    It use for backporting features of other python version to
    current python version, not like original import.

.. _future: https://docs.python.org/2/reference/simple_stmts.html#future
__ future_


Check object attributes
-----------------------

.. code-block:: python

    # example of check list attributes
    >>> dir(list)
    ['__add__', '__class__', ...]

Define a function ``__doc__``
------------------------------

.. code-block:: python

    # Define a function document
    >>> def example():
    ...   """ This is an example function """
    ...   print("Example function")
    ...
    >>> example.__doc__
    ' This is an example function '

    # Or using help function
    >>> help(example)

Check instance type
-------------------

.. code-block:: python

    >>> ex = 10
    >>> isinstance(ex,int)
    True

Check, Get, Set attribute
-------------------------

.. code-block:: python

    >>> class Example(object):
    ...   def __init__(self):
    ...     self.name = "ex"
    ...   def printex(self):
    ...     print("This is an example")
    ...

    # Check object has attributes
    # hasattr(obj, 'attr')
    >>> ex = Example()
    >>> hasattr(ex,"name")
    True
    >>> hasattr(ex,"printex")
    True
    >>> hasattr(ex,"print")
    False

    # Get object attribute
    # getattr(obj, 'attr')
    >>> getattr(ex,'name')
    'ex'

    # Set object attribute
    # setattr(obj, 'attr', value)
    >>> setattr(ex,'name','example')
    >>> ex.name
    'example'

Check inheritance
-----------------

.. code-block:: python

    >>> class Example(object):
    ...   def __init__(self):
    ...     self.name = "ex"
    ...   def printex(self):
    ...     print("This is an Example")
    ...
    >>> issubclass(Example, object)
    True

Check all global variables
--------------------------

.. code-block:: python

    # globals() return a dictionary
    # {'variable name': variable value}
    >>> globals()
    {'args': (1, 2, 3, 4, 5), ...}

Check **callable**
-------------------

.. code-block:: python

    >>> a = 10
    >>> def fun():
    ...   print("I am callable")
    ...
    >>> callable(a)
    False
    >>> callable(fun)
    True

Get function/class name
-----------------------

.. code-block:: python

    >>> class ExampleClass(object):
    ...   pass
    ...
    >>> def example_function():
    ...   pass
    ...
    >>> ex = ExampleClass()
    >>> ex.__class__.__name__
    'ExampleClass'
    >>> example_function.__name__
    'example_function'


``__new__`` & ``__init__``
--------------------------

.. code-block:: python

    # __init__ will invoke
    >>> class ClassA(object):
    ...     def __new__(cls, arg):
    ...         print('__new__ ' + arg)
    ...         return object.__new__(cls, arg)
    ...     def __init__(self, arg):
    ...         print('__init__ ' + arg)
    ...
    >>> o = ClassA("Hello")
    __new__ Hello
    __init__ Hello

    # __init__ won't be invoke
    >>> class ClassB(object):
    ...     def __new__(cls, arg):
    ...         print('__new__ ' + arg)
    ...         return object
    ...     def __init__(self, arg):
    ...         print('__init__ ' + arg)
    ...
    >>> o = ClassB("Hello")
    __new__ Hello


The diamond problem
--------------------

.. code-block:: python

    # The problem of multiple inheritance in searching a method

    >>> def foo_a(self):
    ...     print("This is ClsA")
    ...
    >>> def foo_b(self):
    ...     print("This is ClsB")
    ...
    >>> def foo_c(self):
    ...     print("This is ClsC")
    ...
    >>> class Type(type):
    ...     def __repr__(cls):
    ...         return cls.__name__
    ...
    >>> ClsA = Type("ClsA", (object,), {'foo': foo_a})
    >>> ClsB = Type("ClsB", (ClsA,), {'foo': foo_b})
    >>> ClsC = Type("ClsC", (ClsA,), {'foo': foo_c})
    >>> ClsD = Type("ClsD", (ClsB, ClsC), {})
    >>> ClsD.mro()
    [ClsD, ClsB, ClsC, ClsA, <type 'object'>]
    >>> ClsD().foo()
    This is ClsB


Representations of your class behave
------------------------------------

.. code-block:: python

    >>> class Example(object):
    ...    def __str__(self):
    ...       return "Example __str__"
    ...    def __repr__(self):
    ...       return "Example __repr__"
    ...
    >>> print(str(Example()))
    Example __str__
    >>> Example()
    Example __repr__

Break up a long string
-----------------------

.. code-block:: python

    # original long string
    >>> s = 'This is a very very very long python string'
    >>> s
    'This is a very very very long python string'

    # single quote with an escaping backslash
    >>> s = "This is a very very very " \
    ...     "long python string"
    >>> s
    'This is a very very very long python string'

    # using brackets
    >>> s = ("This is a very very very "
    ...      "long python string")
    >>> s
    'This is a very very very long python string'

    # using '+'
    >>> s = ("This is a very very very " +
    ...      "long python string")
    >>> s
    'This is a very very very long python string'

    # using triple-quote with an escaping backslash
    >>> s = '''This is a very very very \
    ... long python string'''
    >>> s
    'This is a very very very long python string'

Get list item **SMART**
------------------------

.. code-block:: python

    >>> a = [1, 2, 3, 4, 5]
    >>> a[0]
    1
    >>> a[-1]
    5
    >>> a[0:]
    [1, 2, 3, 4, 5]
    >>> a[:-1]
    [1, 2, 3, 4]

    # a[start:end:step]
    >>> a[0:-1:2]
    [1, 3]

    # using slice object
    # slice(start,end,step)
    >>> s = slice(0, -1, 2)
    >>> a[s]
    [1, 3]

    # Get index and item in loop
    >>> for i, v in enumerate(range(3)):
    ...     print((i, v))
    ...
    (0, 0)
    (1, 1)
    (2, 2)

    # Transfer two list into tuple list
    >>> a = [1, 2, 3, 4, 5]
    >>> b = [2, 4, 5, 6, 8]
    >>> zip(a, b)
    [(1, 2), (2, 4), (3, 5), (4, 6), (5, 8)]

    # with filter
    >>> [x for x in range(5) if x > 1]
    [2, 3, 4]
    >>> l = ['1', '2', 3, 'Hello', 4]
    >>> predicate = lambda x: isinstance(x, int)
    >>> filter(predicate, l)
    [3, 4]

    # collect distinct objects
    >>> a = [1, 2, 3, 3, 3]
    >>> list({_ for _ in a})
    [1, 2, 3]
    # or
    >>> list(set(a))
    [1, 2, 3]

    # reverse
    >>> a = [1, 2, 3, 4, 5]
    >>> a[::-1]
    [5, 4, 3, 2, 1]

    # be careful
    >>> a = [[]] * 3
    >>> b = [[] for _ in range(3)]
    >>> a[0].append("Hello")
    >>> a
    [['Hello'], ['Hello'], ['Hello']]
    >>> b[0].append("Python")
    >>> b
    [['Python'], [], []]


Get dictionary item **SMART**
------------------------------

.. code-block:: python

    # get dictionary all keys
    >>> a = {"1":1, "2":2, "3":3}
    >>> b = {"2":2, "3":3, "4":4}
    >>> a.keys()
    ['1', '3', '2']

    # get dictionary key and value as tuple
    >>> a.items()
    [('1', 1), ('3', 3), ('2', 2)]

    # find same key between two dictionary
    >>> [_ for _ in a.keys() if _ in b.keys()]
    ['3', '2']
    # better way
    >>> c = set(a).intersection(set(b))
    >>> list(c)
    ['3', '2']
    # or
    >>> [_ for _ in a if _ in b]
    ['3', '2']

    # update dictionary
    >>> a.update(b)
    >>> a
    {'1': 1, '3': 3, '2': 2, '4': 4}

Set a list/dict **SMART**
--------------------------

.. code-block:: python

    # get a list with init value
    >>> ex = [0] * 10
    >>> ex
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    # extend two list
    >>> a = [1, 2, 3]; b = ['a', 'b']
    >>> a + b
    [1, 2, 3, 'a', 'b']

    # using list comprehension
    >>> [x for x in range(10)]
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    >>> fn = lambda x: x**2
    >>> [fn(x) for x in range(5)]
    [0, 1, 4, 9, 16]
    >>> {'{0}'.format(x): x for x in range(3)}
    {'1': 1, '0': 0, '2': 2}

    # using builtin function "map"
    >>> map(fn, range(5))
    [0, 1, 4, 9, 16]


``set`` operations
-------------------

.. code-block:: python

    # set comprehension
    >>> a = [1, 2, 5, 6, 6, 6, 7]
    >>> s = {x for x in a}
    >>> s
    set([1, 2, 5, 6, 7])
    >>> s = {x for x in a if x > 3}
    >>> s
    set([5, 6, 7])
    >>> s = {x if x > 3 else -1 for x in a}
    >>> s
    set([6, 5, -1, 7])

    # uniquify list
    >>> a = [1, 2, 2, 2, 3, 4, 5, 5]
    >>> a
    [1, 2, 2, 2, 3, 4, 5, 5]
    >>> ua = list(set(a))
    >>> ua
    [1, 2, 3, 4, 5]

    # union two set
    >>> a = set([1, 2, 2, 2, 3])
    >>> b = set([5, 5, 6, 6, 7])
    >>> a | b
    set([1, 2, 3, 5, 6, 7])
    # or
    >>> a = [1, 2, 2, 2, 3]
    >>> b = [5, 5, 6, 6, 7]
    >>> set(a + b)
    set([1, 2, 3, 5, 6, 7])

    # append item to set
    >>> a = set([1, 2, 3, 3, 3])
    >>> a.add(5)
    >>> a
    set([1, 2, 3, 5])
    # or
    >>> a = set([1, 2, 3, 3, 3])
    >>> a |= set([1, 2, 3, 4, 5, 6])
    >>> a
    set([1, 2, 3, 4, 5, 6])

    # intersection two set
    >>> a = set([1, 2, 2, 2, 3])
    >>> b = set([1, 5, 5, 6, 6, 7])
    >>> a & b
    set([1])

    # get two list common items
    >>> a = [1, 1, 2, 3]
    >>> b = [1, 3, 5, 5, 6, 6]
    >>> com = list(set(a) & set(b))
    >>> com
    [1, 3]

    # b contains a
    >>> a = set([1, 2])
    >>> b = set([1, 2, 5, 6])
    >>> a <=b
    True

    # a contains b
    >>> a = set([1, 2, 5, 6])
    >>> b = set([1, 5, 6])
    >>> a >= b
    True

    # set diff
    >>> a = set([1, 2, 3])
    >>> b = set([1, 5, 6, 7, 7])
    >>> a - b
    set([2, 3])

    # symmetric diff
    >>> a = set([1,2,3])
    >>> b = set([1, 5, 6, 7, 7])
    >>> a ^ b
    set([2, 3, 5, 6, 7])

NamedTuple
----------

.. code-block:: python

    # namedtuple(typename, field_names)
    # replace define class without method
    >>> from collections import namedtuple
    >>> Example = namedtuple("Example",'a b c')
    >>> e = Example(1, 2, 3)
    >>> print(e.a, e[1], e[1] + e.b)
    1 2 4

``__iter__`` - Delegating Iteration
------------------------------------

.. code-block:: python

    # __iter__ return an iterator object
    # Be careful: list is an "iterable" object not an "iterator"
    >>> class Iter(object):
    ...     def __init__(self, list_):
    ...         self._list = list_
    ...     def __iter__(self):
    ...         return iter(self._list)
    ...
    >>> it = Iter([1, 2, 3])
    >>> for i in it:
    ...     print(i)
    ...
    1
    2
    3

Using Generator as Iterator
---------------------------

.. code-block:: python

    # see: PEP289
    >>> for x in g:
    ...     print(x, end=' ')
    ... else:
    ...     print()
    ...
    0 1 2 3 4 5 6 7 8 9

    # equivalent to
    >>> def generator():
    ...     for x in range(10):
    ...         yield x
    ...
    >>> g = generator()
    >>> for x in g:
    ...     print(x, end=' ')
    ... else:
    ...     print()
    ...
    0 1 2 3 4 5 6 7 8 9

Emulating a list
----------------

.. code-block:: python

    >>> class EmuList(object):
    ...   def __init__(self, list_):
    ...     self._list = list_
    ...   def __repr__(self):
    ...     return "EmuList: " + repr(self._list)
    ...   def append(self, item):
    ...     self._list.append(item)
    ...   def remove(self, item):
    ...     self._list.remove(item)
    ...   def __len__(self):
    ...     return len(self._list)
    ...   def __getitem__(self, sliced):
    ...     return self._list[sliced]
    ...   def __setitem__(self, sliced, val):
    ...     self._list[sliced] = val
    ...   def __delitem__(self, sliced):
    ...     del self._list[sliced]
    ...   def __contains__(self, item):
    ...     return item in self._list
    ...   def __iter__(self):
    ...     return iter(self._list)
    ...
    >>> emul = EmuList(range(5))
    >>> emul
    EmuList: [0, 1, 2, 3, 4]
    >>> emul[1:3]  #  __getitem__
    [1, 2]
    >>> emul[0:4:2]  #  __getitem__
    [0, 2]
    >>> len(emul)  #  __len__
    5
    >>> emul.append(5)
    >>> emul
    EmuList: [0, 1, 2, 3, 4, 5]
    >>> emul.remove(2)
    >>> emul
    EmuList: [0, 1, 3, 4, 5]
    >>> emul[3] = 6  # __setitem__
    >>> emul
    EmuList: [0, 1, 3, 6, 5]
    >>> 0 in emul  # __contains__
    True


Emulating a dictionary
----------------------

.. code-block:: python

    >>> class EmuDict(object):
    ...   def __init__(self, dict_):
    ...     self._dict = dict_
    ...   def __repr__(self):
    ...     return "EmuDict: " + repr(self._dict)
    ...   def __getitem__(self, key):
    ...     return self._dict[key]
    ...   def __setitem__(self, key, val):
    ...     self._dict[key] = val
    ...   def __delitem__(self, key):
    ...     del self._dict[key]
    ...   def __contains__(self, key):
    ...     return key in self._dict
    ...   def __iter__(self):
    ...     return iter(self._dict.keys())
    ...
    >>> _ = {"1":1, "2":2, "3":3}
    >>> emud = EmuDict(_)
    >>> emud  # __repr__
    EmuDict: {'1': 1, '2': 2, '3': 3}
    >>> emud['1']  # __getitem__
    1
    >>> emud['5'] = 5  # __setitem__
    >>> emud
    EmuDict: {'1': 1, '2': 2, '3': 3, '5': 5}
    >>> del emud['2']  # __delitem__
    >>> emud
    EmuDict: {'1': 1, '3': 3, '5': 5}
    >>> for _ in emud:
    ...     print(emud[_], end=' ')  # __iter__
    ... else:
    ...     print()
    ...
    1 3 5
    >>> '1' in emud  # __contains__
    True


Decorator
---------

.. code-block:: python

    # see: PEP318
    >>> from functools import wraps
    >>> def decorator(func):
    ...   @wraps(func)
    ...   def wrapper(*args, **kwargs):
    ...     print("Before calling {}.".format(func.__name__))
    ...     ret = func(*args, **kwargs)
    ...     print("After calling {}.".format(func.__name__))
    ...     return ret
    ...   return wrapper
    ...
    >>> @decorator
    ... def example():
    ...   print("Inside example function.")
    ...
    >>> example()
    Before calling example.
    Inside example function.
    After calling example.

    # equivalent to
    ... def example():
    ...   print("Inside example function.")
    ...
    >>> example = decorator(example)
    >>> example()
    Before calling example.
    Inside example function.
    After calling example.

.. note::

    ``@wraps`` preserve attributes of the original function,
    otherwise attributes of decorated function will be replaced
    by **wrapper function**

.. code-block:: python

    # without @wraps
    >>> def decorator(func):
    ...     def wrapper(*args, **kwargs):
    ...         print('wrap function')
    ...         return func(*args, **kwargs)
    ...     return wrapper
    ...
    >>> @decorator
    ... def example(*a, **kw):
    ...     pass
    ...
    >>> example.__name__  # attr of function lose
    'wrapper'

    # with @wraps
    >>> from functools import wraps
    >>> def decorator(func):
    ...     @wraps(func)
    ...     def wrapper(*args, **kwargs):
    ...         print('wrap function')
    ...         return func(*args, **kwargs)
    ...     return wrapper
    ...
    >>> @decorator
    ... def example(*a, **kw):
    ...     pass
    ...
    >>> example.__name__  # attr of function preserve
    'example'


Decorator with arguments
------------------------

.. code-block:: python

    >>> from functools import wraps
    >>> def decorator_with_argument(val):
    ...   def decorator(func):
    ...     @wraps(func)
    ...     def wrapper(*args, **kwargs):
    ...       print("Val is {0}".format(val))
    ...       return func(*args, **kwargs)
    ...     return wrapper
    ...   return decorator
    ...
    >>> @decorator_with_argument(10)
    ... def example():
    ...   print("This is example function.")
    ...
    >>> example()
    Val is 10
    This is example function.

    # equivalent to
    >>> def example():
    ...   print("This is example function.")
    ...
    >>> example = decorator_with_argument(10)(example)
    >>> example()
    Val is 10
    This is example function.

for: exp else: exp
------------------

.. code-block:: python

    # see document: More Control Flow Tools
    # forloop’s else clause runs when no break occurs
    >>> for x in range(5):
    ...     print(x, end=' ')
    ... else:
    ...     print("\nno break occurred")
    ...
    0 1 2 3 4
    no break occurred
    >>> for x in range(5):
    ...     if x % 2 == 0:
    ...         print("break occurred")
    ...         break
    ... else:
    ...     print("no break occurred")
    ...
    break occurred

    # above statement equivalent to
    >>> flag = False
    >>> for x in range(5):
    ...     if x % 2 == 0:
    ...         flag = True
    ...         print("break occurred")
    ...         break
    ...
    ... if flag == False:
    ...     print("no break occurred")
    ...
    break occurred

try: exp else: exp
------------------

.. code-block:: python

    # No exception occur will go into else.
    >>> try:
    ...     print("No exception")
    ... except:
    ...     pass
    ... else:
    ...     print("No exception occurred")
    ...
    No exception
    No exception occurred

Lambda function
---------------

.. code-block:: python

    >>> fn = lambda x: x**2
    >>> fn(3)
    9
    >>> (lambda x: x**2)(3)
    9
    >>> (lambda x: [x*_ for _ in range(5)])(2)
    [0, 2, 4, 6, 8]
    >>> (lambda x: x if x>3 else 3)(5)
    5

    # multiline lambda example
    >>> (lambda x:
    ... True
    ... if x>0
    ... else
    ... False)(3)
    True

Option arguments - (\*args, \*\*kwargs)
---------------------------------------

.. code-block:: python

    >>> def example(a, b=None, *args, **kwargs):
    ...     print(a, b)
    ...     print(args)
    ...     print(kwargs)
    ...
    >>> example(1, "var", 2, 3, word="hello")
    1 var
    (2, 3)
    {'word': 'hello'}
    >>> a_tuple = (1, 2, 3, 4, 5)
    >>> a_dict = {"1":1, "2":2, "3":3}
    >>> example(1, "var", *a_tuple, **a_dict)
    1 var
    (1, 2, 3, 4, 5)
    {'1': 1, '2': 2, '3': 3}

``type()`` declare (create) a ``class``
----------------------------------------

.. code-block:: python

    >>> def fib(self, n):
    ...     if n <= 2:
    ...         return 1
    ...     return fib(self, n-1) + fib(self, n-2)
    ...
    >>> Fib = type('Fib', (object,), {'val': 10,
    ...                               'fib': fib})
    >>> f = Fib()
    >>> f.val
    10
    >>> f.fib(f.val)
    55

    # equal to
    >>> class Fib(object):
    ...     val = 10
    ...     def fib(self, n):
    ...         if n <=2:
    ...             return 1
    ...         return self.fib(n-1)+self.fib(n-2)
    ...
    >>> f = Fib()
    >>> f.val
    10
    >>> f.fib(f.val)
    55


Callable object
---------------

.. code-block:: python

    >>> class CallableObject(object):
    ...   def example(self, *args, **kwargs):
    ...     print("I am callable!")
    ...   def __call__(self, *args, **kwargs):
    ...     self.example(*args, **kwargs)
    ...
    >>> ex = CallableObject()
    >>> ex()
    I am callable!

Context Manager - ``with`` statement
-------------------------------------

.. code-block:: python

    # replace try: ... finally: ...
    # see: PEP343
    # common use in open and close

    import socket

    class Socket(object):
        def __init__(self,host,port):
            self.host = host
            self.port = port

        def __enter__(self):
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind((self.host,self.port))
            sock.listen(5)
            self.sock = sock
            return self.sock

        def __exit__(self,*exc_info):
            if exc_info[0] is not None:
                import traceback
                traceback.print_exception(*exc_info)
            self.sock.close()

    if __name__=="__main__":
        host = 'localhost'
        port = 5566
        with Socket(host, port) as s:
            while True:
                conn, addr = s.accept()
                msg = conn.recv(1024)
                print(msg)
                conn.send(msg)
                conn.close()

Using ``@contextmanager``
--------------------------

.. code-block:: python

    from contextlib import contextmanager

    @contextmanager
    def opening(filename, mode='r'):
       f = open(filename, mode)
       try:
          yield f
       finally:
          f.close()

    with opening('example.txt') as fd:
       fd.read()

Using ``with`` statement open file
------------------------------------

.. code-block:: python

    >>> with open("/etc/passwd",'r') as f:
    ...    content = f.read()

Reading file chunk
-------------------

.. code-block:: python


    >>> chunk_size = 16
    >>> content = ''
    >>> with open('/etc/hosts') as f:
    ...     for c in iter(lambda: f.read(chunk_size), ''):
    ...         content += c
    ...
    >>> print(content)
    127.0.0.1	localhost
    255.255.255.255	broadcasthost
    ::1             localhost

    10.245.1.3  www.registry.io

Property - Managed attributes
-----------------------------

.. code-block:: python

    >>> class Example(object):
    ...     def __init__(self, value):
    ...        self._val = value
    ...     @property
    ...     def val(self):
    ...         return self._val
    ...     @val.setter
    ...     def val(self, value):
    ...         if not isintance(value, int):
    ...             raise TypeError("Expected int")
    ...         self._val = value
    ...     @val.deleter
    ...     def val(self):
    ...         del self._val
    ...
    >>> ex = Example(123)
    >>> ex.val = "str"
    Traceback (most recent call last):
      File "", line 1, in
      File "test.py", line 12, in val
        raise TypeError("Expected int")
    TypeError: Expected int

    # equivalent to
    >>> class Example(object):
    ...     def __init__(self, value):
    ...        self._val = value
    ...
    ...     def _val_getter(self):
    ...         return self._val
    ...
    ...     def _val_setter(self, value):
    ...         if not isintance(value, int):
    ...             raise TypeError("Expected int")
    ...         self._val = value
    ...
    ...     def _val_deleter(self):
    ...         del self._val
    ...
    ...     val = property(fget=_val_getter, fset=_val_setter, fdel=_val_deleter, doc=None)
    ...

Computed attributes - Using property
------------------------------------

.. code-block:: python

    >>> class Example(object):
    ...   @property
    ...   def square3(self):
    ...     return 2**3
    ...
    >>> ex = Example()
    >>> ex.square3
    8

.. note::

    ``@property`` compute the value of attribute only when we need.
    Not store in memory previously.

Descriptor - manage attributes
------------------------------

.. code-block:: python

    >>> class Integer(object):
    ...   def __init__(self, name):
    ...     self._name = name
    ...   def __get__(self, inst, cls):
    ...     if inst is None:
    ...       return self
    ...     else:
    ...       return inst.__dict__[self._name]
    ...   def __set__(self, inst, value):
    ...     if not isinstance(value, int):
    ...       raise TypeError("Expected int")
    ...     inst.__dict__[self._name] = value
    ...   def __delete__(self,inst):
    ...     del inst.__dict__[self._name]
    ...
    >>> class Example(object):
    ...   x = Integer('x')
    ...   def __init__(self, val):
    ...     self.x = val
    ...
    >>> ex1 = Example(1)
    >>> ex1.x
    1
    >>> ex2 = Example("str")
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "<stdin>", line 4, in __init__
      File "<stdin>", line 11, in __set__
    TypeError: Expected an int
    >>> ex3 = Example(3)
    >>> hasattr(ex3, 'x')
    True
    >>> del ex3.x
    >>> hasattr(ex3, 'x')
    False

``@staticmethod``, ``@classmethod``
-------------------------------------

.. code-block:: python

    # @classmethod: bound to class
    # @staticmethod: like python function but in class
    >>> class example(object):
    ...   @classmethod
    ...   def clsmethod(cls):
    ...     print("I am classmethod")
    ...   @staticmethod
    ...   def stmethod():
    ...     print("I am staticmethod")
    ...   def instmethod(self):
    ...     print("I am instancemethod")
    ...
    >>> ex = example()
    >>> ex.clsmethod()
    I am classmethod
    >>> ex.stmethod()
    I am staticmethod
    >>> ex.instmethod()
    I am instancemethod
    >>> example.clsmethod()
    I am classmethod
    >>> example.stmethod()
    I am staticmethod
    >>> example.instmethod()
    Traceback (most recent call last):
      File "", line 1, in
    TypeError: unbound method instmethod() ...

Abstract method - Metaclass
---------------------------

.. code-block:: python

    # usually using in define methods but not implement
    >>> from abc import ABCMeta, abstractmethod
    >>> class base(object):
    ...   __metaclass__ = ABCMeta
    ...   @abstractmethod
    ...   def absmethod(self):
    ...     """ Abstract method """
    ...
    >>> class example(base):
    ...   def absmethod(self):
    ...     print("abstract")
    ...
    >>> ex = example()
    >>> ex.absmethod()
    abstract

    # another better way to define a meta class
    >>> class base(object):
    ...   def absmethod(self):
    ...     raise NotImplementedError
    ...
    >>> class example(base):
    ...   def absmethod(self):
    ...     print("abstract")
    ...
    >>> ex = example()
    >>> ex.absmethod()
    abstract

Common Use **Magic**
---------------------

.. code-block:: python

    # see python document: data model
    # For command class
    __main__
    __name__
    __file__
    __module__
    __all__
    __dict__
    __class__
    __doc__
    __init__(self, [...)
    __str__(self)
    __repr__(self)
    __del__(self)

    # For Descriptor
    __get__(self, instance, owner)
    __set__(self, instance, value)
    __delete__(self, instance)

    # For Context Manager
    __enter__(self)
    __exit__(self, exc_ty, exc_val, tb)

    # Emulating container types
    __len__(self)
    __getitem__(self, key)
    __setitem__(self, key, value)
    __delitem__(self, key)
    __iter__(self)
    __contains__(self, value)

    # Controlling Attribute Access
    __getattr__(self, name)
    __setattr__(self, name, value)
    __delattr__(self, name)
    __getattribute__(self, name)

    # Callable object
    __call__(self, [args...])

    # Compare related
    __cmp__(self, other)
    __eq__(self, other)
    __ne__(self, other)
    __lt__(self, other)
    __gt__(self, other)
    __le__(self, other)
    __ge__(self, other)

    # arithmetical operation related
    __add__(self, other)
    __sub__(self, other)
    __mul__(self, other)
    __div__(self, other)
    __mod__(self, other)
    __and__(self, other)
    __or__(self, other)
    __xor__(self, other)


Parsing csv string
--------------------

.. code-block:: python

    # python2 and python3 compatible

    >>> try:
    ...     from StringIO import StringIO # for py2
    ... except ImportError:
    ...     from io import StringIO # for py3
    ...
    >>> import csv
    >>> s = "foo,bar,baz"
    >>> f = StringIO(s)
    >>> for x in csv.reader(f): print(x)
    ...
    ['foo', 'bar', 'baz']

    # or

    >>> import csv
    >>> s = "foo,bar,baz"
    >>> for x in csv.reader([s]): print(x)
    ...
    ['foo', 'bar', 'baz']


Using ``__slots__`` to save memory
-----------------------------------

.. code-block:: python

    #!/usr/bin/env python3

    import resource
    import platform
    import functools


    def profile_mem(func):
        @functools.wraps(func)
        def wrapper(*a, **k):
            s = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
            ret = func(*a, **k)
            e = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss

            uname = platform.system()
            if uname == "Linux":
                print(f"mem usage: {e - s} kByte")
            elif uname == "Darwin":
                print(f"mem usage: {e - s} Byte")
            else:
                raise Exception("not support")
            return ret
        return wrapper


    class S(object):
        __slots__ = ['attr1', 'attr2', 'attr3']

        def __init__(self):
            self.attr1 = "Foo"
            self.attr2 = "Bar"
            self.attr3 = "Baz"


    class D(object):

        def __init__(self):
            self.attr1 = "Foo"
            self.attr2 = "Bar"
            self.attr3 = "Baz"


    @profile_mem
    def alloc(cls):
        _ = [cls() for _ in range(1000000)]


    alloc(S)
    alloc(D)

output:

.. code-block:: console

    $ python3.6 s.py
    mem usage: 70922240 Byte
    mem usage: 100659200 Byte


Using annotation for type hints
--------------------------------

.. code-block:: python

    #!/usr/bin/env python3

    # need python3.5 or above (PEP: 484, 526, 3107)

    from functools import wraps

    from typing import (
        Dict,
        Tuple,
        List,
        Set,
        Generator,
        Type,
        TypeVar
    )

    # use annotation to do type hints (without type check)
    def func(n: int) -> int:
        return n

    def func(s: str) -> str:
        return s

    def func(d: Dict) -> Dict:
        return d

    def func(l: List) -> List:
        return l

    def func(t: Tuple) -> Tuple:
        return t

    def func(s: Set) -> Set:
        return s

    def func(g: Generator) -> Generator:
        return g

    class C(object):
        pass

    TC = TypeVar('C', bound=C)

    def func(cls: Type) -> TC:
        print("cls is Type? ", isinstance(cls, Type))
        return cls()

    # Based on TypeVar document, isinstance() and issubclass()
    # should not be used with types. Thus, we us type(c) is C
    # to check the type of instance
    c = func(C)
    print("return the instance of class C? ", type(c) is C)


Using annotation to check type
-------------------------------

.. code-block:: python

    # need python3 (PEP: 3107)
    from functools import wraps

    import inspect

    ANNO_EMPTY = inspect._empty

    def check_args(sig, *a, **k):
        bind = sig.bind(*a, **k)
        params = sig.parameters
        for name, val in bind.arguments.items():
            anno = params[name].annotation
            if anno is ANNO_EMPTY:
                continue
            if isinstance(val, anno):
                continue
            atype = type(val)
            raise TypeError(f"type({name}) is '{anno}', not '{atype}'")


    def check_ret(sig, ret):
        anno = sig.return_annotation
        if anno is ANNO_EMPTY:
            return ret
        elif isinstance(ret, anno):
            return ret

        rtype = type(ret)
        raise TypeError(f"type(ret) is '{anno}', not '{rtype}'")



    def typechecked(func):
        sig = inspect.signature(func)

        @wraps(func)
        def wrapper(*a, **k):
            check_args(sig, *a, **k)
            return check_ret(sig, func(*a, **k))
        return wrapper


    @typechecked
    def test1(a: int)->int:
        return a

    @typechecked
    def test2(a: int):
        return a

    @typechecked
    def test3(a)->str:
        return a

    @typechecked
    def test4(a, b: str, c: str="c")->list:
        return [a, b, c]

    print(test1(9527))
    print(test2(9487))
    print(test3("Hello Python3"))
    print(test4(9487, "bb", c="cc"))

    try:
        print(test3(9487))
    except TypeError as e:
        print(e)

    try:
        print(test4(5566, 9527))
    except TypeError as e:
        print(e)

    try:
        print(test4(123, "b", c=5566))
    except TypeError as e:
        print(e)


output:

.. code-block:: console

    9527
    9487
    Hello Python3
    [9487, 'bb', 'cc']
    type(ret) is '<class 'str'>', not '<class 'int'>'
    type(b) is '<class 'str'>', not '<class 'int'>'
    type(c) is '<class 'str'>', not '<class 'int'>'
