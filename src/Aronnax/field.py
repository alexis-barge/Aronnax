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
        if not self.save:
            self.reload()
        if rank < 0 or rank >= self.nchunk:
            raise ValueError(f"Invalid chunk value: must be between 0 and {self.nchunk-1}") 
        return self._backend.get_local(self.name, rank, self.id)

    def __setitem__(self, rank, val):
        """
        ... 

        """
        if rank < 0 or rank >= self.nchunk:
            raise ValueError(f"Invalid chunk value: must be between 0 and {self.nchunk-1}") 
        self._backend.set_local(self.name, rank, val)

    def reload(self):
        """ ... """
        self.free()
        self._backend.pull(self.name, self.id)

    def impose(self):
        """ ... """
        self._backend.push(self.name, self.id)

    def apply(self, func, arg_fields, impose=True):
        """
        ...

        """
        self.reload() if not self.save else None
        for f in arg_fields:
            f.reload() if not f.save else None
        self._backend.apply(func, self.id, arg_fields)
       
        if impose:
            self.impose()
        else:
            self.save = True

    def free(self):
        """ ... """
        self._backend.purge(self.id)
