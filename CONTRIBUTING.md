# How to contribute

Contributions and feedbacks are welcome. We appreciate the time and effort you are ready to invest for collaborating to this project.


## Code of Conduct

Everyone participating in the Eophis project is expected to treat other people with respect and, more generally, to follow guidelines articulated in the [Python Community Code of Conduct](https://policies.python.org/python.org/code-of-conduct/).


## Bug reports and feature requests

For bug reports, feature requests, and suggestions, please [open an issue](https://github.com/alexis-barge/pyNEMO/issues).

For bugs, please also provide:

- your operating system name and version
- pyNEMO and NEMO version
- Self-contained code snippet to reproduce the bug


## Developer's guide

If you have built something upon pyNEMO (or wish to):

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a branch for local development and make changes locally
4. Commit your changes and push your branch to GitHub
5. Submit a pull request through the GitHub website

When creating a pull request, discussion will be open to decide in which branch your contributions should be merged. If your contribution implies new features, please provide testing procedures.


### Coding convention

**c_bind sources - Fortran**

Modified and additional NEMO sources with C-exposed functions. The philosophy is to call isolate parts of NEMO sources using simple incoming instructions. 
The sources can be modified to be split up, called in a different order, repeated, given overriding instructions or return informations about NEMO internal state. 
However, they should not be modified in a way that makes NEMO perform tasks it was not originally designed to handle. 
Unusual or exotic behavior should instead be managed by the higher level pyNEMO module. 

Coding C-binded sources must follow conventions described in section *G. Coding Rules* of the [NEMO book](https://zenodo.org/records/8167700).


**py_bind sources - Cython**

Cython sources only aim to wrapp C-exposed Fortran functions in Python. No convention here, reduce coding for converting variables and calling Fortran sources.


**pyNEMO sources - Python**

pyNEMO provides an intuitive API of the Python wrapper. It follows [PEP 8 coding convention](https://peps.python.org/pep-0008/). Here are some additional guidelines:

- Avoid obscure or too long variable names
- Use 4-space indentation
- Document every function, class...with [Numpy doscstring style](https://numpydoc.readthedocs.io/en/latest/format.html)
- Coding is art, aesthetics matters =D

Module structure:

- Add module header with short description of the module, License and copyright
- When importing packages, distinguish pyNEMO module and external packages
- Define exactly what should be imported from the module with ``__all__``, even to import everything or nothing
