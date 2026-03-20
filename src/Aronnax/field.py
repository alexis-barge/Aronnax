# field.py

class DistributedField:
    """
    This class ...

    Attributes
    ----------
    ...

    """
    _hash = 0

    def __init__(self, backend, name, save=False):
        self._backend = backend
        self.name = name
        self.nchunk = backend.nproc
        self.save = save
        self.id = str( DistributedField._hash )
        DistributedField._hash += 1
        self.reload()

    def __del__(self):
        if self._backend.process is not None:
            self.free()

    def __getitem__(self, rank):
        """
        ... 

        """
        # Update array content
        if not self.save:
            self.reload()

        # Check chunk value
        if rank < 0 or rank >= self.nchunk:
            raise ValueError(f"Invalid chunk value: must be between 0 and {self.nchunk-1}")

        # Get array chunk
        try:
            fld = self._backend.get_local(self.name, rank, self.id)
        except Exception as e:
            print(e)
            fld = None
    
        return fld


    def __setitem__(self, rank, val):
        """
        ... 

        """
        # Check chunk value
        if rank < 0 or rank >= self.nchunk:
            raise ValueError(f"Invalid chunk value: must be between 0 and {self.nchunk-1}") 
        
        # Send array
        try:
            self._backend.set_local(self.name, rank, val)
        except Exception as e:
            print(e)


    def reload(self):
        """ ... """
        self.free()
        try:
            self._backend.pull(self.name, self.id)
        except Exception as e:
            print(e)


    def impose(self):
        """ ... """
        try:
            self._backend.push(self.name, self.id)
        except Exception as e:
            print(e)


    def apply(self, func, arg_fields, impose=True):
        """
        ...

        """
        self.reload() if not self.save else None
        
        for f in arg_fields:
            f.reload() if not f.save else None
        
        try:
            self._backend.apply(func, self.id, arg_fields)
        except Exception as e:
            print(e)
       
        if impose:
            self.impose()
        else:
            self.save = True


    def free(self):
        """ ... """
        try:
            self._backend.purge(self.id)
        except Exception as e:
            print(e)
