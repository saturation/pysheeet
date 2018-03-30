=======================
Python C API cheatsheet
=======================

.. contents:: Table of Contents
    :backlinks: none


Performance of ctypes
----------------------

.. code-block:: c

    // fib.c
    unsigned int fib(unsigned int n)
    {
        if ( n < 2) {
            return n;
        }
        return fib(n-1) + fib(n-2);
    }


Building a libfib.dylib (Mac OSX)

.. code-block:: bash

    clang -Wall -Werror -shared -fPIC -o libfib.dylib fib.c

Comparing the performance

.. code-block:: python

    >>> import time
    >>> from ctypes import *
    >>> def fib(n):
    ...     if n < 2:
    ...         return n
    ...     return fib(n-1) + fib(n-2)
    ...
    >>> s = time.time(); fib(35); e = time.time()
    9227465
    >>> print("cost time: {} sec".format(e - s))
    cost time: 4.09563493729 sec
    >>> libfib = CDLL("./libfib.dylib")
    >>> s = time.time(); libfib.fib(35); e = time.time()
    9227465
    >>> print("cost time: {} sec".format(e - s))
    cost time: 0.0819959640503 sec


Error handling when use ctypes
-------------------------------

.. code-block:: python

    from __future__ import print_function

    import errno
    import os

    from ctypes import *
    from sys import platform, maxsize

    is_64bits = maxsize > 2**32

    if is_64bits and platform == 'darwin':
        libc = CDLL("libc.dylib", use_errno=True)
    else:
        raise RuntimeError("Not support platform: {}".format(platform))

    stat = libc.stat

    class Stat(Structure):
        '''
        From /usr/include/sys/stat.h

        struct stat {
            dev_t	  st_dev;
            ino_t	  st_ino;
            mode_t	  st_mode;
            nlink_t	  st_nlink;
            uid_t	  st_uid;
            gid_t	  st_gid;
            dev_t	  st_rdev;
        #ifndef _POSIX_SOURCE
            struct	timespec st_atimespec;
            struct	timespec st_mtimespec;
            struct	timespec st_ctimespec;
        #else
            time_t	  st_atime;
            long	  st_atimensec;
            time_t	  st_mtime;
            long	  st_mtimensec;
            time_t	  st_ctime;
            long	  st_ctimensec;
        #endif
            off_t	  st_size;
            int64_t	  st_blocks;
            u_int32_t     st_blksize;
            u_int32_t     st_flags;
            u_int32_t     st_gen;
            int32_t	  st_lspare;
            int64_t	  st_qspare[2];
        };
        '''
        _fields_ = [('st_dev',        c_ulong),
                    ('st_ino',        c_ulong),
                    ('st_mode',       c_ushort),
                    ('st_nlink',      c_uint),
                    ('st_uid',        c_uint),
                    ('st_gid',        c_uint),
                    ('st_rdev',       c_ulong),
                    ('st_atime',      c_longlong),
                    ('st_atimendesc', c_long),
                    ('st_mtime',      c_longlong),
                    ('st_mtimendesc', c_long),
                    ('st_ctime',      c_longlong),
                    ('st_ctimendesc', c_long),
                    ('st_size',       c_ulonglong),
                    ('st_blocks',     c_int64),
                    ('st_blksize',    c_uint32),
                    ('st_flags',      c_uint32),
                    ('st_gen',        c_uint32),
                    ('st_lspare',     c_int32),
                    ('st_qspare',     POINTER(c_int64) * 2)]

    # stat success
    path = create_string_buffer(b"/etc/passwd")
    st = Stat()
    ret = stat(path, byref(st))
    assert ret == 0

    # if stat fail, check errno
    path = create_string_buffer(b"&%$#@!")
    st = Stat()
    ret = stat(path, byref(st))
    if ret != 0:
        errno_ = get_errno() # get errno
        errmsg = "stat({}) failed. {}".format(path.raw, os.strerror(errno_))
        raise OSError(errno_, errmsg)

output:

.. code-block:: console

    $ python err_handling.py   # python2
    Traceback (most recent call last):
      File "err_handling.py", line 85, in <module>
        raise OSError(errno_, errmsg)
    OSError: [Errno 2] stat(&%$#@!) failed. No such file or directory

    $ python3 err_handling.py  # python3
    Traceback (most recent call last):
      File "err_handling.py", line 85, in <module>
        raise OSError(errno_, errmsg)
    FileNotFoundError: [Errno 2] stat(b'&%$#@!\x00') failed. No such file or directory


Getting File System Type
-------------------------

.. code-block:: python


    from __future__ import print_function

    from ctypes import *
    from sys import platform

    if platform not in ('linux', 'linux2'):
        raise RuntimeError("Not support '{}'".format(platform))


    # from Linux/include/uapi/linux/magic.h

    EXT_SUPER_MAGIC      = 0x137D
    EXT2_OLD_SUPER_MAGIC = 0xEF51
    EXT2_SUPER_MAGIC     = 0xEF53
    EXT3_SUPER_MAGIC     = 0xEF53
    EXT4_SUPER_MAGIC     = 0xEF53
    BTRFS_SUPER_MAGIC    = 0x9123683E


    class KernelFsid(Structure):
        '''
        From Linux/arch/mips/include/asm/posix_types.h

        typedef struct {
                long    val[2];
        } __kernel_fsid_t;
        '''
        _fields_ = [('val', POINTER(c_long) * 2)]

    class Statfs(Structure):
        '''
        From Linux/arch/mips/include/asm/statfs.h

        struct statfs {
                long            f_type;
        #define f_fstyp f_type
                long            f_bsize;
                long            f_frsize;
                long            f_blocks;
                long            f_bfree;
                long            f_files;
                long            f_ffree;
                long            f_bavail;

                /* Linux specials */
                __kernel_fsid_t f_fsid;
                long            f_namelen;
                long            f_flags;
                long            f_spare[5];
        };
        '''
        _fields_ = [('f_type',    c_long),
                    ('f_bsize',   c_long),
                    ('f_frsize',  c_long),
                    ('f_block',   c_long),
                    ('f_bfree',   c_long),
                    ('f_files',   c_long),
                    ('f_ffree',   c_long),
                    ('f_fsid',    KernelFsid),
                    ('f_namelen', c_long),
                    ('f_flags',   c_long),
                    ('f_spare',   POINTER(c_long) * 5)]


    libc = CDLL('libc.so.6', use_errno=True)
    statfs = libc.statfs

    path = create_string_buffer(b'/etc')
    fst = Statfs()
    ret = statfs(path, byref(fst))
    assert ret == 0

    print('Is ext4? {}'.format(fst.f_type == EXT4_SUPER_MAGIC))

output:

.. code-block:: console

    $ python3 statfs.py
    Is ext4? True


Doing Zero-copy via sendfile
-----------------------------

.. code-block:: python

    from __future__ import print_function, unicode_literals

    import os
    import sys
    import errno
    import platform

    from ctypes import *

    # check os
    p = platform.system()
    if p != "Linux":
        raise OSError("Not support '{}'".format(p))

    # check linux version
    ver = platform.release()
    if tuple(map(int, ver.split('.'))) < (2,6,33):
        raise OSError("Upgrade kernel after 2.6.33")

    # check input arguments
    if len(sys.argv) != 3:
        print("Usage: sendfile.py f1 f2", file=sys.stderr)
        exit(1)

    libc = CDLL('libc.so.6', use_errno=True)
    sendfile = libc.sendfile

    src = sys.argv[1]
    dst = sys.argv[2]
    src_size = os.stat(src).st_size

    # clean destination first
    try:
        os.remove(dst)
    except OSError as e:
        if e.errno != errno.ENOENT: raise

    offset = c_int64(0)

    with open(src, 'r') as f1:
        with open(dst, 'w') as f2:
            src_fd = c_int(f1.fileno())
            dst_fd = c_int(f2.fileno())
            ret = sendfile(dst_fd, src_fd, byref(offset), src_size) 
            if ret < 0:
                errno_ = get_errno()
                errmsg = "sendfile failed. {}".format(os.strerror(errno_))
                raise OSError(errno_, errmsg)

output:

.. code-block:: console

    $ python3 sendfile.py /etc/resolv.conf resolve.conf; cat resolve.conf
    nameserver	192.168.1.1


PyObject header
---------------

.. code-block:: c

    // ref: python source code
    // Python/Include/object.c
    #define _PyObject_HEAD_EXTRA \
        struct _object *_ob_next;\
        struct _object *_ob_prev;

    #define PyObject_HEAD    \
        _PyObject_HEAD_EXTRA \
        Py_ssize_t ob_refcnt;\
        struct _typeobject *ob_type;

Python C API Template
---------------------

C API source
~~~~~~~~~~~~

.. code-block:: c

    #include <Python.h>

    typedef struct {
        PyObject_HEAD
    } spamObj;

    static PyTypeObject spamType = {
        PyObject_HEAD_INIT(&PyType_Type)
        0,                  //ob_size
        "spam.Spam",        //tp_name
        sizeof(spamObj),    //tp_basicsize
        0,                  //tp_itemsize
        0,                  //tp_dealloc
        0,                  //tp_print
        0,                  //tp_getattr
        0,                  //tp_setattr
        0,                  //tp_compare
        0,                  //tp_repr
        0,                  //tp_as_number
        0,                  //tp_as_sequence
        0,                  //tp_as_mapping
        0,                  //tp_hash
        0,                  //tp_call
        0,                  //tp_str
        0,                  //tp_getattro
        0,                  //tp_setattro
        0,                  //tp_as_buffer
        Py_TPFLAGS_DEFAULT, //tp_flags
        "spam objects",     //tp_doc
    };

    static PyMethodDef spam_methods[] = {
        {NULL}  /* Sentinel */
    };

    /* declarations for DLL import */
    #ifndef PyMODINIT_FUNC
    #define PyMODINIT_FUNC void
    #endif

    PyMODINIT_FUNC 
    initspam(void)
    {
        PyObject *m;
        spamType.tp_new = PyType_GenericNew;
        if (PyType_Ready(&spamType) < 0) {
            goto END;
        }
        m = Py_InitModule3("spam", spam_methods, "Example of Module");
        Py_INCREF(&spamType);
        PyModule_AddObject(m, "spam", (PyObject *)&spamType);
    END:
        return;
    }

Prepare setup.py
~~~~~~~~~~~~~~~~

.. code-block:: python

    from distutils.core import setup
    from distutils.core import Extension

    setup(name="spam",
          version="1.0",
          ext_modules=[Extension("spam", ["spam.c"])])

Build C API source
~~~~~~~~~~~~~~~~~~

.. code-block:: console

    $ python setup.py build
    $ python setup.py install

Run the C module
~~~~~~~~~~~~~~~~

.. code-block:: python

    >>> import spam
    >>> spam.__doc__
    'Example of Module'
    >>> spam.spam
    <type 'spam.Spam'>

PyObject with Member and Methods
--------------------------------

C API source
~~~~~~~~~~~~


.. code-block:: c

    #include <Python.h>
    #include <structmember.h>

    typedef struct {
        PyObject_HEAD
        PyObject *hello;
        PyObject *world;
        int spam_id;
    } spamObj;

    static void
    spamdealloc(spamObj *self)
    {
        Py_XDECREF(self->hello);
        Py_XDECREF(self->world);
        self->ob_type
            ->tp_free((PyObject*)self);
    }

    /* __new__ */
    static PyObject *
    spamNew(PyTypeObject *type, PyObject *args, PyObject *kwds)
    {
        spamObj *self = NULL;

        self = (spamObj *)
               type->tp_alloc(type, 0);
        if (self == NULL) {
            goto END; 
        } 
        /* alloc str to hello */
        self->hello = 
            PyString_FromString("");
        if (self->hello == NULL)
        {
            Py_XDECREF(self);
            self = NULL;
            goto END;
        }
        /* alloc str to world */
        self->world = 
            PyString_FromString("");
        if (self->world == NULL)
        {
            Py_XDECREF(self);
            self = NULL;
            goto END;
        }
        self->spam_id = 0;
    END:
        return (PyObject *)self;
    }

    /* __init__ */
    static int 
    spamInit(spamObj *self, PyObject *args, PyObject *kwds)
    {
        int ret = -1;
        PyObject *hello=NULL, 
                 *world=NULL, 
                 *tmp=NULL;

        static char *kwlist[] = {
            "hello", 
            "world", 
            "spam_id", NULL};

        /* parse input arguments */
        if (! PyArg_ParseTupleAndKeywords(
              args, kwds, 
              "|OOi", 
              kwlist, 
              &hello, &world, 
              &self->spam_id)) {
            goto END;
        }
        /* set attr hello */
        if (hello) {
            tmp = self->hello;
            Py_INCREF(hello);
            self->hello = hello;
            Py_XDECREF(tmp);
        }
        /* set attr world */
        if (world) {
            tmp = self->world;
            Py_INCREF(world);
            self->world = world;
            Py_XDECREF(tmp);
        }
        ret = 0;
    END:
        return ret;
    }

    static long 
    fib(long n) {
        if (n<=2) {
            return 1;
        }
        return fib(n-1)+fib(n-2);
    }

    static PyObject *
    spamFib(spamObj *self, PyObject *args)
    {
        PyObject  *ret = NULL;
        long arg = 0;

        if (!PyArg_ParseTuple(args, "i", &arg)) {
            goto END;
        }
        ret = PyInt_FromLong(fib(arg)); 
    END:
        return ret;
    }

    //ref: python doc
    static PyMemberDef spam_members[] = {
        /* spameObj.hello*/
        {"hello",                   //name
         T_OBJECT_EX,               //type
         offsetof(spamObj, hello),  //offset 
         0,                         //flags
         "spam hello"},             //doc
        /* spamObj.world*/
        {"world", 
         T_OBJECT_EX,
         offsetof(spamObj, world), 
         0,
         "spam world"},
        /* spamObj.spam_id*/
        {"spam_id", 
         T_INT, 
         offsetof(spamObj, spam_id), 
         0,
         "spam id"},
        /* Sentiel */
        {NULL}
    };

    static PyMethodDef spam_methods[] = {
        /* fib */
        {"spam_fib", 
         (PyCFunction)spamFib, 
         METH_VARARGS,
         "Calculate fib number"},
        /* Sentiel */
        {NULL}
    };

    static PyMethodDef module_methods[] = {
        {NULL}  /* Sentinel */
    };

    static PyTypeObject spamKlass = {
        PyObject_HEAD_INIT(NULL)
        0,                               //ob_size
        "spam.spamKlass",                //tp_name
        sizeof(spamObj),                 //tp_basicsize
        0,                               //tp_itemsize
        (destructor) spamdealloc,        //tp_dealloc
        0,                               //tp_print
        0,                               //tp_getattr
        0,                               //tp_setattr
        0,                               //tp_compare
        0,                               //tp_repr
        0,                               //tp_as_number
        0,                               //tp_as_sequence
        0,                               //tp_as_mapping
        0,                               //tp_hash 
        0,                               //tp_call
        0,                               //tp_str
        0,                               //tp_getattro
        0,                               //tp_setattro
        0,                               //tp_as_buffer
        Py_TPFLAGS_DEFAULT | 
        Py_TPFLAGS_BASETYPE,             //tp_flags
        "spamKlass objects",             //tp_doc 
        0,                               //tp_traverse
        0,                               //tp_clear
        0,                               //tp_richcompare
        0,                               //tp_weaklistoffset
        0,                               //tp_iter
        0,                               //tp_iternext
        spam_methods,                    //tp_methods
        spam_members,                    //tp_members
        0,                               //tp_getset
        0,                               //tp_base
        0,                               //tp_dict
        0,                               //tp_descr_get
        0,                               //tp_descr_set
        0,                               //tp_dictoffset
        (initproc)spamInit,              //tp_init
        0,                               //tp_alloc
        spamNew,                         //tp_new
    };

    /* declarations for DLL import */
    #ifndef PyMODINIT_FUNC 
    #define PyMODINIT_FUNC void
    #endif

    PyMODINIT_FUNC
    initspam(void)
    {
        PyObject* m;

        if (PyType_Ready(&spamKlass) < 0) {
            goto END;
        }

        m = Py_InitModule3(
          "spam",         // Mod name 
          module_methods, // Mod methods
          "Spam Module"); // Mod doc  

        if (m == NULL) {
            goto END;
        }
        Py_INCREF(&spamKlass);
        PyModule_AddObject(
          m,                           // Module    
          "SpamKlass",                 // Class Name
          (PyObject *) &spamKlass);    // Class
    END:
        return;
    }

Compare performance with pure Python
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

    >>> import spam
    >>> o = spam.SpamKlass()
    >>> def profile(func):
    ...     def wrapper(*args, **kwargs):
    ...         s = time.time()
    ...         ret = func(*args, **kwargs)
    ...         e = time.time()
    ...         print e-s
    ...     return wrapper
    ...
    >>> def fib(n):
    ...     if n <= 2:
    ...         return n
    ...     return fib(n-1)+fib(n-2)
    ... 
    >>> @profile
    ... def cfib(n):
    ...     o.spam_fib(n)
    ...
    >>> @profile
    ... def pyfib(n):
    ...     fib(n)
    ...
    >>> cfib(30)
    0.0106310844421
    >>> pyfib(30)
    0.399799108505
