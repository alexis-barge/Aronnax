# field.py

class DistributedField:
    _hash = 0

    def __init__(self, backend, name, save=False):
        self._backend = backend
        self.name = name
        self.nchunk = backend.nproc
        self.save = save
        self.id = str( DistributedField._hash )
        DistributedField._hash += 1

    def __del__(self):
        self.free()

    def __getitem__(self, rank):
        self.chunk(rank)

    def chunk(self, rank):
        if rank < 0 or rank >= self.nchunk:
            raise ValueError(f"Invalid chunk value: must be between 0 and {self.nchunk-1}") 
        return self._backend.get_local(self.name, rank, self.id)

    def free(self):
        self._backend.purge(self.id)
