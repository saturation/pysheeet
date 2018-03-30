==========================
Python unicode cheatsheet
==========================

.. contents:: Table of Contents
    :backlinks: none


Encode: unicode code point to bytes
------------------------------------

.. code-block:: python

    >>> s = u'Café'
    >>> type(s.encode('utf-8'))
    <class 'bytes'>

Decode: bytes to unicode code point
------------------------------------

.. code-block:: python

    >>> s = bytes('Café', encoding='utf-8')
    >>> s.decode('utf-8')
    'Café'

Get unicode code point
-----------------------

.. code-block:: python

    >>> s = u'Café'
    >>> for _c in s: print('U+%04x' % ord(_c))
    ... 
    U+0043
    U+0061
    U+0066
    U+00e9
    >>> u = '中文'
    >>> for _c in u: print('U+%04x' % ord(_c))
    ... 
    U+4e2d
    U+6587

python2 ``str`` is equivalent to byte string
---------------------------------------------

.. code-block:: python

    >>> s = 'Café'  # byte string
    >>> s
    'Caf\xc3\xa9'
    >>> type(s)
    <type 'str'>
    >>> u = u'Café' # unicode string
    >>> u
    u'Caf\xe9'
    >>> type(u)
    <type 'unicode'>


python3 ``str`` is equivalent to unicode string 
-------------------------------------------------

.. code-block:: python

    >>> s = 'Café'
    >>> type(s)
    <class 'str'>
    >>> s
    'Café'
    >>> s.encode('utf-8')
    b'Caf\xc3\xa9'
    >>> s.encode('utf-8').decode('utf-8')
    'Café'


python2 take ``str`` char as byte character
--------------------------------------------

.. code-block:: python

    >>> s= 'Café'
    >>> print [_c for _c in s]
    ['C', 'a', 'f', '\xc3', '\xa9']
    >>> len(s)
    5
    >>> s = u'Café'
    >>> print [_c for _c in s]
    [u'C', u'a', u'f', u'\xe9']
    >>> len(s)
    4

python3 take ``str`` char as unicode character
-----------------------------------------------

.. code-block:: python

    >>> s = 'Café'
    >>> print([_c for _c in s])
    ['C', 'a', 'f', 'é']
    >>> len(s)
    4
    >>> bs = bytes(s, encoding='utf-8')
    >>> print(bs)
    b'Caf\xc3\xa9'
    >>> len(bs)
   5 


unicode normalization
----------------------

.. code-block:: python

    # python 3
    >>> u1 = 'Café'       # unicode string
    >>> u2 = 'Cafe\u0301'
    >>> u1, u2
    ('Café', 'Café')
    >>> len(u1), len(u2)
    (4, 5)
    >>> u1 == u2
    False
    >>> u1.encode('utf-8') # get u1 byte string
    b'Caf\xc3\xa9'
    >>> u2.encode('utf-8') # get u2 byte string
    b'Cafe\xcc\x81'
    >>> from unicodedata import normalize
    >>> s1 = normalize('NFC', u1)  # get u1 NFC format 
    >>> s2 = normalize('NFC', u2)  # get u2 NFC format
    >>> s1 == s2
    True
    >>> s1.encode('utf-8'), s2.encode('utf-8')
    (b'Caf\xc3\xa9', b'Caf\xc3\xa9')
    >>> s1 = normalize('NFD', u1)  # get u1 NFD format
    >>> s2 = normalize('NFD', u2)  # get u2 NFD format
    >>> s1, s2
    ('Café', 'Café')
    >>> s1 == s2
    True
    >>> s1.encode('utf-8'), s2.encode('utf-8')
    (b'Cafe\xcc\x81', b'Cafe\xcc\x81') 

    

