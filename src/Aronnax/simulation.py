# simulation.py
import f90nml
import glob
import shutil
import os

class Run:
    """
    This class represents a run with NEMO: current ite, namelists, restart directories,
    potential kept-in-memory fields...

    Attributes
    ----------
    ...

    """
    def __init__(self, label):
        
        self._label = label
        self._lock = False
        self.copy_from(None)


    def format_date(self):
        """ ... """
        yy = int( self.run._time // 31536000.0 )
        mm = int( (self.run._time - yy*31536000.0) // 2678400.0 )
        dd = int( (self.run._time - yy*31536000.0 - mm*2678400.0 ) // 86400.0 )
        return f"{yy:02d}y" + f"{mm:02d}m" + f"{dd:02d}d"


    def next_restart(self, end_ite=self._ite):
        """ 
        Returns next iteration to reach from a given one
        to make NEMO write the restart files

        """
        # OCE
        rst_oce = max(self._ite + 1, end_ite)
        
        # ICE
        if self._nml_itm("nn_ice") == 2 :
            it0 = self._nml_itm("nn_it000")
            fsbc = self._nml_itm("fsbc")

            if (self._ite - it0) % fsbc == 0:
                min_ice = self._ite + (self._ite - it0) % fsbc + 2*fsbc - 1
            else:
                min_ice = self._ite + fsbc - (self._ite - it0) % fsbc + 2*fsbc - 1
            
            if ( end_ite - fsbc - (end_ite - it0) % fsbc ) >= self._ite:
                max_ice = end_ite - (end_ite - it0) % fsbc + fsbc - 1
            else:
                max_ice = end_ite + fsbc - (end_ite - it0) % fsbc + fsbc - 1
            
            rst_ice = max( min_ice, max_ice )
        
        else:
            rst_ice = -1

        return max( rst_oce, rst_ice )


    def copy_from(self, previous_run):
        """ 
        ... 
        
        """
        # dumping directory
        self._dump_dir = os.path.join(os.getcwd(),self._label)
        if os.path.isdir(self._dump_dir):
            print(f"Warning: directory {dump_dir} exists and will be overwritten at dumping"
        
        # update namelists
        if previous_run is not None:
            restart_dir = os.path.join( os.getcwd(), previous_run )
            if not os.path.isdir( restart_dir ):
                print(f"Directory {restart_dir} does not exist - skipped")
                return
            else:
                self._read_all_nml( restart_dir , "." + previous_run )
                self._cfg["namrun"]["ln_rstart"] = True
                self._cfg["namrun"]["cn_ocerst_in"] = "restart"
                self._cfg["namrun"]["cn_ocerst_indir"] = restart_dir
                self._cfg["namrun"]["nn_it000"] = self._nml_itm("nn_itend") + 1
                self._ice_cfg["namrun"]["cn_icerst_in"] = "restart_ice"
                self._ice_cfg["nampar"]["cn_icerst_indir"] = restart_dir
        else:
            self._read_all_nml()
            self._cfg["namrun"]["nn_it000"] = 1
            self._cfg["namrun"]["ln_rstart"] = False
                  
        self._cfg["namrun"]["cn_exp"] = self._label
        self._cfg["namrun"]["cn_ocerst_out"] = "restart"
        self._cfg["namrun"]["cn_ocerst_outdir"] = self._dump_dir
        self._cfg["namrun"]["nn_itend"] = self._nml_itm("nn_it000") + 1000000 
        self._ice_cfg["nampar"]["cn_icerst_out"] = "restart_ice"
        self._ice_cfg["nampar"]["cn_icerst_outdir"] = self._dump_dir

        # (re)init
        self.reset()


    def reset(self):
        """ ... """
        self._ite = self._nml_itm("nn_it000")
        self._step = self._nml_itm("rn_Dt")
        self._time = 0.0
        self._date = None
        self._date0 = self._nml_itm("nn_date0")


    def dump(self):
        """ ... """
        # dumping directory
        if os.path.isdir(self._dump_dir):
            os.rmdir(self._dump_dir)
            os.mkdirs(self._dump_dir, exist_ok=True)
        
        # dump namelists
        self._cfg["namrun"]["nn_itend"] = self._ite
        self._write_all_nml( self._dump_dir, "." + self._label )

        # save run files
        shutil.copy( "ocean.output", self._dump_dir + "/ocean.output." + self._label )

        for file in glob.glob( self._nml_itm("cn_exp") + "*.nc") ):
            # restart - rename
            if "restart" in file:
                new_name = file.replace( self._nml_itm("cn_exp") + f"_{self._ite-1:08d}_" , "")
                shutil.move( file, os.path.join(dump_dir,new_name) )
        
            # results
            else:
                shutil.move( file, dump_dir )


    def _read_all_nml(self, nml_dir=os.getcwd(), suffix=""):
        """ ... """
        # OCE and ICE only for now
        self._cfg = self._read_nml( os.path.join(nml_dir , "namelist_cfg" + suffix) )
        self._ref = self._read_nml( os.path.join(nml_dir , "namelist_ref" + suffix) )
        self._ice_cfg = self._read_nml( os.path.join(nml_dir , "namelist_ice_cfg" + suffix) )
        self._ice_ref = self._read_nml( os.path.join(nml_dir , "namelist_ice_ref" + suffix) )


    def _write_all_nml(self, output_dir=os.getcwd(), suffix=""):
        """ ... """
        # OCE and ICE only for now
        self._write_nml( self._cfg, os.path.join(output_dir, "namelist_cfg" + suffix) )
        self._write_nml( self._ref, os.path.join(output_dir, "namelist_ref" + suffix) )
        self._write_nml( self._ice_cfg, os.path.join(output_dir, "namelist_ice_cfg" + suffix) )
        self._write_nml( self._ice_ref, os.path.join(output_dir, "namelist_ice_ref" + suffix) )


    def _read_nml(self, nml_name):
        """ 
        Reads namelist under Fortran format
 
            Parameters
            ----------
            output_file : string
                namelist file name

        """
        try:
            nml = f90nml.read(nml_name)
        except:
            print(f"Fortran namelist {nml_name} not found")
            nml = f90nml.Namelist()
        return nml


    def _write_nml(self, nml, output_file):
        """ 
        Writes namelist under Fortran format
 
            Parameters
            ----------
            output_file : string
                namelist file name

        """
        f90nml.write(nml,output_file,force=True)


    def _nml_itm(self, item_label):
        """
        ...
        
        """
        # Search first in OCE and ICE cfg, then ref with same order
        for nml in [ self._cfg, self._ref, self._ice_cfg, self._ice_ref ]:
            item_val = [ gr2 for gr1,gr2 in nml.groups() if item_label.lower() in gr1 ]
            if len(item_val) != 0:
                return item[0]

        print(f"Item {item_label} not found in {self._label} namelists")
        return None
