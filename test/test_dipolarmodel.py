from deerlab.dipolarkernel import dipolarkernel
from deerlab.utils.utils import ovl
from deerlab.whitegaussnoise import whitegaussnoise
import numpy as np
import matplotlib.pyplot as plt
from deerlab.model import Model,fit
from deerlab.dipolarmodel import ExperimentInfo, dipolarmodel, ex_4pdeer, ex_3pdeer, ex_5pdeer
from deerlab import dd_gauss,dd_gauss2,bg_hom3d,bg_exp
import deerlab as dl 

# ======================================================================
def test_type(): 
    "Check that the function returns a valid model type"

    model = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)

    assert isinstance(model,Model)
# ======================================================================

# ======================================================================
def test_Nparam_1(): 
    "Check that the function has the correct number of nonlinear parameters"

    model = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)

    assert model.Nnonlin==5 and model.Nlin==1 and model.Nparam==6
# ======================================================================

# ======================================================================
def test_Nparam_2(): 
    "Check that the function has the correct number of nonlinear parameters"

    model = dipolarmodel(t,r,dd_gauss2,bg_hom3d,npathways=2)

    assert model.Nnonlin==9 and model.Nlin==2 and model.Nparam==11
# ======================================================================

# ======================================================================
def test_preservation(): 
    "Check that the inputs models are not modified by the output model"

    model = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=2)
    model.mean.par0 = 15

    assert model.mean.par0==15 and dd_gauss.mean.par0!=15
# ======================================================================

# ======================================================================
def test_names(): 
    "Check that the model has correct parameter names"

    model = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)
    parameters = ['mean','width','conc','mod','reftime','scale']
    
    for param in parameters:
        assert hasattr(model,param)
# ======================================================================


t = np.linspace(-0.5,5,100)
r = np.linspace(2,5,50)
Bfcn = lambda t,lam: bg_hom3d(t,50,lam)
Bfcn_pheno = lambda t,_: bg_exp(t,0.1)
Pr = dd_gauss(r,3,0.2)
V1path = 1e5*dipolarkernel(t,r,mod=0.3,bg=Bfcn)@Pr
V1path_noB = 1e5*dipolarkernel(t,r,mod=0.3)@Pr
V1path_phenoB = 1e5*dipolarkernel(t,r,mod=0.3,bg=Bfcn_pheno)@Pr
V2path = 1e5*dipolarkernel(t,r,pathways=[[0.6],[0.3,0],[0.1,2]],bg=Bfcn)@Pr
V3path = 1e5*dipolarkernel(t,r,pathways=[[0.5],[0.3,0],[0.1,2],[0.1,5]],bg=Bfcn)@Pr


# ======================================================================
def test_call_positional(): 
    "Check that the model called via positional arguments responds correctly"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)
    
    Vsim = Vmodel(0.3,0.0,50,3,0.2,1e5)

    assert np.allclose(Vsim,V1path)
# ======================================================================

# ======================================================================
def test_call_keywords(): 
    "Check that the model called via keyword arguments responds correctly"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)
    
    Vsim = Vmodel(mod=0.3,reftime=0.0,conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V1path)
# ======================================================================

# ======================================================================
def test_phenomenological_Bmodel(): 
    "Check model generation of a dipolar signal with a phenomelogical background"

    Vmodel = dipolarmodel(t,r,dd_gauss,Bmodel=bg_exp,npathways=1)
    
    Vsim = Vmodel(mod=0.3,reftime=0.0,mean=3,width=0.2,decay=0.1,scale=1e5)

    assert np.allclose(Vsim,V1path_phenoB)
# ======================================================================

# ======================================================================
def test_no_Bmodel(): 
    "Check model generation of a dipolar signal without background"

    Vmodel = dipolarmodel(t,r,dd_gauss,None,npathways=1)
    
    Vsim = Vmodel(mod=0.3,reftime=0.0,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V1path_noB)
# ======================================================================

# ======================================================================
def test_model_1pathways(): 
    "Check that the model with one dipolar pathway is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)
    
    Vsim = Vmodel(mod=0.3,reftime=0.0,conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V1path)
# ======================================================================

# ======================================================================
def test_model_2pathways(): 
    "Check that the model with two dipolar pathways is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=2)
    
    Vsim = Vmodel(lam1=0.3,reftime1=0.0,lam2=0.1,
                    reftime2=2,conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V2path)
# ======================================================================

# ======================================================================
def test_model_3pathways(): 
    "Check that the model with three dipolar pathways is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=3)
    
    Vsim = Vmodel(lam1=0.3,reftime1=0.0,
                lam2=0.1,reftime2=2, lam3=0.1, reftime3=5,
                conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V3path)
# ======================================================================


# ======================================================================
def test_fit_1pathways(): 
    "Check that the model can be correctly fitted with one dipolar pathway"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1)
    
    result = fit(Vmodel,V1path,nonlin_tol=1e-3)

    assert np.allclose(result.model,V1path)
# ======================================================================

# ======================================================================
def test_fit_2pathways(): 
    "Check that the model can be correctly fitted with two dipolar pathways"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=2)
    Vmodel.reftime1.freeze(0)
    Vmodel.reftime2.freeze(2)
    
    result = fit(Vmodel,V2path,nonlin_tol=1e-3)

    assert np.allclose(result.model,V2path)
# ======================================================================


# ======================================================================
def test_fit_3pathways(): 
    "Check that the model can be correctly fitted with three dipolar pathways"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=3)
    Vmodel.reftime1.freeze(0)
    Vmodel.reftime2.freeze(2)
    Vmodel.reftime3.freeze(5)
    
    result = fit(Vmodel,V3path,nonlin_tol=1e-3)

    assert np.allclose(result.model,V3path)
# ======================================================================


V1harm = 1e5*dipolarkernel(t,r,pathways=[[0.7],[0.3,0,1]],bg=Bfcn)@Pr
V2harm = 1e5*dipolarkernel(t,r,pathways=[[0.6],[0.3,0,1],[0.1,2,2]],bg=Bfcn)@Pr
V3harm = 1e5*dipolarkernel(t,r,pathways=[[0.5],[0.3,0,1],[0.1,2,2],[0.1,5,3]],bg=Bfcn)@Pr


# ======================================================================
def test_model_1harmonics(): 
    "Check that the model with one harmonic is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=1,harmonics=1)
    
    Vsim = Vmodel(mod=0.3,reftime=0.0,conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V1harm)
# ======================================================================

# ======================================================================
def test_model_2harmonics(): 
    "Check that the model with two different harmonics is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=2,harmonics=[1,2])
    
    Vsim = Vmodel(lam1=0.3,reftime1=0.0,lam2=0.1,
                    reftime2=2,conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V2harm)
# ======================================================================

# ======================================================================
def test_model_3harmonics(): 
    "Check that the model with three different harmonics is correct"

    Vmodel = dipolarmodel(t,r,dd_gauss,bg_hom3d,npathways=3,harmonics=[1,2,3])
    
    Vsim = Vmodel(lam1=0.3,reftime1=0.0,
                lam2=0.1,reftime2=2, lam3=0.1, reftime3=5,
                conc=50,mean=3,width=0.2,scale=1e5)

    assert np.allclose(Vsim,V3harm)
# ======================================================================

# ======================================================================
def test_call_Pnonparametric(): 
    "Check that the model with one dipolar pathway is correct"

    Vmodel = dipolarmodel(t,r,Bmodel=bg_hom3d,npathways=1)
    Vsim = Vmodel(mod=0.3,reftime=0.0,conc=50,P=1e5*dd_gauss(r,3,0.2))

    assert np.allclose(Vsim,V1path)
# ======================================================================

# ======================================================================
def test_fit_Pnonparametric(): 
    "Check that the model with one dipolar pathway is correct"

    Vmodel = dipolarmodel(t,r,Bmodel=bg_hom3d,npathways=1)
    
    result = fit(Vmodel,V1path,nonlin_tol=1e-3)

    assert np.allclose(result.model,V1path,atol=1e-2) and np.allclose(result.P/1e5,Pr,atol=1e-3)
# ======================================================================

tau1,tau2,tau3 = 1,2,3
V3pulse = 1e5*dipolarkernel(t,r,pathways=[[0.6],[0.3,0],[0.1,tau1]],bg=Bfcn)@Pr
V4pulse = 1e5*dipolarkernel(t,r,pathways=[[0.6],[0.3,tau1],[0.1,tau1+tau2]],bg=Bfcn)@Pr
V5pulse = 1e5*dipolarkernel(t,r,pathways=[[0.6],[0.3,tau3],[0.1,tau2]],bg=Bfcn)@Pr

# ======================================================================
def test_ex_3pdeer_type(): 
    "Check the 3-pulse DEER experimental model."

    experiment = ex_3pdeer(tau1)

    assert isinstance(experiment,ExperimentInfo) 
# ======================================================================

# ======================================================================
def test_ex_3pdeer_fit(): 
    "Check the 3-pulse DEER experimental model."

    experiment = ex_3pdeer(tau1)
    Vmodel = dipolarmodel(t,r,Bmodel=bg_hom3d,npathways=2,experiment=experiment)
    result = fit(Vmodel,V3pulse,nonlin_tol=1e-3)

    assert np.allclose(V3pulse,result.model,atol=1e-2) and ovl(result.P/1e5,Pr)>0.975
# ======================================================================

# ======================================================================
def test_ex_4pdeer_type(): 
    "Check the 4-pulse DEER experimental model."

    experiment = ex_4pdeer(tau1,tau2)

    assert isinstance(experiment,ExperimentInfo) 
# ======================================================================

# ======================================================================
def test_ex_4pdeer_fit(): 
    "Check the 4-pulse DEER experimental model."

    experiment = ex_4pdeer(tau1,tau2)
    Vmodel = dipolarmodel(t,r,Bmodel=bg_hom3d,npathways=2,experiment=experiment)
    result = fit(Vmodel,V4pulse,nonlin_tol=1e-3)

    assert np.allclose(V4pulse,result.model,atol=1e-2) and ovl(result.P/1e5,Pr)>0.975
# ======================================================================

# ======================================================================
def test_ex_5pdeer_type(): 
    "Check the 5-pulse DEER experimental model."

    experiment = ex_5pdeer(tau1,tau2,tau3)

    assert isinstance(experiment,ExperimentInfo) 
# ======================================================================

# ======================================================================
def test_ex_5pdeer_fit(): 
    "Check the 5-pulse DEER experimental model in fitting."

    experiment = ex_5pdeer(tau1,tau2,tau3)
    Vmodel = dipolarmodel(t,r,Bmodel=bg_hom3d,npathways=2,experiment=experiment)
    result = fit(Vmodel,V5pulse,nonlin_tol=1e-3)

    assert np.allclose(V5pulse,result.model,atol=1e-2) and ovl(result.P/1e5,Pr)>0.975
# ======================================================================