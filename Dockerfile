# Container for DUNE ND MC production

# Do everywhere: RUN yum install -y --setopt=tsflags=nodocs --setopt=tsflags=nodocs python python-setuptools python-pip && yum clean all

# Start with latest CentOS
FROM centos:7.6.1810

ARG N_CORE=1

# Set up a more modern system (gcc6)
RUN yum install -y --setopt=tsflags=nodocs centos-release-scl && yum clean all
RUN yum install -y --setopt=tsflags=nodocs devtoolset-6 && yum clean all
SHELL ["scl", "enable", "devtoolset-6"]

RUN echo BUILDING WITH ${N_CORE} CORES

# Get some useful packages
RUN yum install -y --setopt=tsflags=nodocs git && yum clean all
RUN yum install -y --setopt=tsflags=nodocs tar && yum clean all
RUN yum install -y --setopt=tsflags=nodocs wget && yum clean all

# Install cmake, by hand....
RUN mkdir -p /opt/cmake-src
WORKDIR /opt/cmake-src
RUN wget https://cmake.org/files/v3.9/cmake-3.9.1.tar.gz
RUN tar xfvz cmake-3.9.1.tar.gz 
WORKDIR /opt/cmake-src/cmake-3.9.1
RUN ./bootstrap
RUN make install -j ${N_CORE}
WORKDIR /opt
RUN rm -rf /opt/cmake-src

# GEANT4
RUN mkdir -p /opt/geant4-src
RUN mkdir -p /opt/geant4-build
RUN mkdir -p /opt/geant4
RUN git clone https://github.com/Geant4/geant4.git /opt/geant4-src
WORKDIR /opt/geant4-src
RUN git checkout tags/v10.3.0

RUN yum install -y --setopt=tsflags=nodocs expat-devel && yum clean all
RUN yum install -y --setopt=tsflags=nodocs xerces-c-devel xerces-c && yum clean all

WORKDIR /opt/geant4-build
RUN cmake /opt/geant4-src/ -DGEANT4_INSTALL_DATA=ON -DCMAKE_INSTALL_PREFIX=/opt/geant4/ -DGEANT4_USE_GDML=ON -DCMAKE_CXX_STANDARD=14
RUN make install -j ${N_CORE}
WORKDIR /opt/
RUN rm -rf /opt/geant4-build /opt/geant4-src

ENV G4DATA /opt/geant4/share/Geant4-10.3.0/data
ENV G4LEDATA ${G4DATA}/G4EMLOW6.50
ENV G4LEVELGAMMADATA ${G4DATA}/PhotonEvaporation4.3
ENV G4NEUTRONHPDATA ${G4DATA}/G4NDL4.5
ENV G4RADIOACTIVEDATA ${G4DATA}/RadioactiveDecay5.1
ENV G4ABLADATA ${G4DATA}/G4ABLA3.0
ENV G4REALSURFACEDATA ${G4DATA}/RealSurface1.0
ENV G4NEUTRONXSDATA ${G4DATA}/G4NEUTRONXS1.4
ENV G4PIIDATA ${G4DATA}/G4PII1.3
ENV G4SAIDXSDATA ${G4DATA}/G4SAIDDATA1.1
ENV G4ENSDFSTATEDATA ${G4DATA}/G4ENSDFSTATE2.1

ENV G4_cmake_file /opt/geant4/lib64/Geant4-10.3.0/Geant4Config.cmake
ENV Geant4_DIR /opt/geant4/lib64/Geant4-10.3.0/

ENV PATH ${PATH}:/opt/geant4/bin

ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/opt/geant4/lib64/


RUN yum install -y --setopt=tsflags=nodocs gsl && yum clean all
RUN yum install -y --setopt=tsflags=nodocs gsl-devel && yum clean all
RUN wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh epel-release-6-8.noarch.rpm
RUN rm -rf epel-release-6-8.noarch.rpm
RUN yum --enablerepo=epel install -y libAfterImage-devel && yum clean all
RUN yum install -y --setopt=tsflags=nodocs glew && yum clean all
RUN yum install -y --setopt=tsflags=nodocs glew-devel && yum clean all
RUN yum install -y --setopt=tsflags=nodocs libXpm-devel && yum clean all
RUN yum install -y --setopt=tsflags=nodocs libXft-devel && yum clean all

RUN yum install -y --setopt=tsflags=nodocs python python-devel && yum clean all
RUN yum install -y --setopt=tsflags=nodocs libxml2 libxml2-devel && yum clean all

# PYTHIA 6
RUN mkdir -p /opt/pythia6-src
WORKDIR /opt/pythia6-src/
RUN wget https://root.cern.ch/download/pythia6.tar.gz
RUN wget --no-check-certificate http://www.hepforge.org/archive/pythia6/pythia-6.4.28.f.gz
RUN gunzip pythia-6.4.28.f.gz
RUN tar xfvz pythia6.tar.gz
RUN mv pythia-6.4.28.f pythia6/pythia6428.f
RUN rm -rf pythia6/pythia6416.f
RUN mv pythia6 /opt/pythia6428
WORKDIR /opt/pythia6428
RUN ./makePythia6.linuxx8664
WORKDIR /opt/
RUN rm -rf /opt/pythia6-src/

# ROOT
RUN mkdir -p /opt/root-src
RUN mkdir -p /opt/root-build
RUN mkdir -p /opt/root
RUN git clone https://github.com/root-project/root.git /opt/root-src
WORKDIR /opt/root-src
RUN git checkout tags/v6-12-06
WORKDIR /opt/root-build
RUN cmake /opt/root-src -DCMAKE_INSTALL_PREFIX=/opt/root  -Dmathmore=ON -Dpythia6=ON -DPYTHIA6_LIBRARY=/opt/pythia6428/libPythia6.so -DCMAKE_CXX_STANDARD=14 -Dcxx14=ON -Dpython=ON
RUN make -j ${N_CORE}
RUN make install -j ${N_CORE}
WORKDIR /opt/
RUN rm -rf /opt/root-src /opt/root-build
ENV ROOTSYS /opt/root/

ENV PATH "${PATH}:/opt/root/bin"
ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/opt/root/lib"

# LHAPDF
RUN mkdir -p /opt/LHAPDF-src
RUN mkdir -p /opt/LHAPDF
WORKDIR /opt/LHAPDF-src
RUN wget http://www.hepforge.org/archive/lhapdf/lhapdf-5.9.1.tar.gz
RUN tar xf lhapdf-5.9.1.tar.gz
WORKDIR /opt/LHAPDF-src/lhapdf-5.9.1
RUN ./configure --prefix=/opt/LHAPDF/
RUN make
RUN make install
WORKDIR /opt
RUN rm -rf /opt/LHAPDF-src
ENV LHAPATH /opt/LHAPDF/share/lhapdf/

RUN mkdir -p /opt/log4cpp-src
RUN mkdir -p /opt/log4cpp
WORKDIR /opt/log4cpp-src
RUN wget 'https://sourceforge.net/projects/log4cpp/files/log4cpp-1.1.x (new)/log4cpp-1.1/log4cpp-1.1.3.tar.gz'
RUN tar xfvz log4cpp-1.1.3.tar.gz
WORKDIR /opt/log4cpp-src/log4cpp
RUN ./configure --prefix=/opt/log4cpp
RUN make install
WORKDIR /opt
RUN rm -rf /opt/log4cpp-src

ENV LOG4CPP_LIB /opt/log4cpp/lib/

RUN yum install -y --setopt=tsflags=nodocs subversion && yum clean all

# What a nice dependency.....
RUN yum install -y --setopt=tsflags=nodocs quota && yum clean all

# GENIE -- apparently prefix option is broken
ENV GENIE /opt/genie/
RUN git clone https://github.com/GENIE-MC/Generator.git /opt/genie
WORKDIR /opt/genie/
RUN git checkout tags/R-2_12_10
RUN ./configure --with-lhapdf-lib=/opt/LHAPDF/lib/ --with-lhapdf-inc=/opt/LHAPDF/include/ --with-pythia6-lib=/opt/pythia6428/ --with-log4cpp-inc=/opt/log4cpp/include/ --with-log4cpp-lib=/opt/log4cpp/lib/ --enable-rwght --enable-fnal
# Not pretty, but let's try this... if it doesn't work, laptop is going out the window..........
RUN sed -i 's/LIBRARIES  := $(LIBRARIES) $(CERN_LIBRARIES) $(GENIE_LIBS)/LIBRARIES  := $(LIBRARIES) $(CERN_LIBRARIES) $(GENIE_LIBS) -lgfortran/g' src/Apps/Makefile
RUN make
RUN make reweight
RUN make install
# Looks like it worked. Laptop safe. Onwards.
ENV PATH ${PATH}:/opt/genie/bin/

# GENIE xsec DefaultPlusValenciaMEC (copied from larsoft)
ADD genie_xsec_v2_12_10_DefaultPlusValenciaMEC.tar.gz /opt/genie_xsec_v2_12_10_DefaultPlusValenciaMEC/data/
ENV GENIEXSECPATH /opt/genie_xsec_v2_12_10_DefaultPlusValenciaMEC/data
ENV GENIEXSECFILE /opt/genie_xsec_v2_12_10_DefaultPlusValenciaMEC/data/gxspl-FNALsmall.xml

ADD genie_phyopt_v2_12_10_dkcharmtau.tar.gz /opt/genie_phyopt_v2_12_10_dkcharmtau
ENV GENIEPHYOPTPATH /opt/genie_phyopt_v2_12_10_dkcharmtau

ENV GXMLPATH /opt/genie_xsec_v2_12_10_DefaultPlusValenciaMEC/data/:/opt/genie_phyopt_v2_12_10_dkcharmtau

RUN cp $GENIE/data/evgen/pdfs/GRV98lo_patched.LHgrid $LHAPATH

# DK2NU
RUN mkdir /opt/dk2nu-src
RUN mkdir /opt/dk2nu-build
RUN mkdir /opt/dk2nu
ENV DK2NU /opt/dk2nu
RUN svn checkout https://cdcvs.fnal.gov/subversion/dk2nu/tags/v01_05_01 /opt/dk2nu-src
WORKDIR /opt/dk2nu-build/
RUN CXXFLAGS="${CXXFLAGS} -I/usr/include/libxml2/ -I/opt/log4cpp/include/" cmake /opt/dk2nu-src/dk2nu -DCMAKE_INSTALL_PREFIX=/opt/dk2nu/ -DTBB_LIBRARY=$ROOTSYS/lib/libtbb.so -DCMAKE_CXX_STANDARD=14
RUN make
RUN make install
WORKDIR /opt/

# edep-sim
RUN mkdir /opt/edep-sim-build
RUN mkdir /opt/edep-sim
RUN git clone https://github.com/ClarkMcGrew/edep-sim.git /opt/edep-sim-src
WORKDIR /opt/edep-sim-src
RUN git checkout tags/2.0.1
WORKDIR /opt/edep-sim-build
RUN cmake /opt/edep-sim-src -DCMAKE_INSTALL_PREFIX=/opt/edep-sim -DCMAKE_CXX_STANDARD=14
RUN make 
RUN make install
WORKDIR /opt/

ENV PATH ${PATH}:/opt/edep-sim/bin
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/opt/edep-sim/lib

# RUN CAF STAGE AS USER
RUN useradd dunendprod
USER dunendprod
WORKDIR /home/dunendprod

# DUNE_ND_CAF
RUN git clone https://github.com/cmmarshall/DUNE_ND_CAF.git /home/dunendprod/DUNE_ND_CAF
ENV NDCAF /home/dunendprod/DUNE_ND_CAF/

WORKDIR /home/dunendprod/DUNE_ND_CAF/
RUN git clone https://github.com/luketpickering/nusystematics.git

WORKDIR /home/dunendprod/DUNE_ND_CAF/nusystematics/
RUN mkdir build
WORKDIR /home/dunendprod/DUNE_ND_CAF/nusystematics/build
RUN cmake ../ -DUSEART=0 -DPYTHIA6=/opt/pythia6428/ -DGENIE=/opt/genie/ -DLHAPDF_LIB=/opt/LHAPDF/lib/ -DLHAPDF_INC=/opt/LHAPDF/include/ -DLHAPATH=/opt/LHAPDF/ -DLIBXML2_INC=/usr/include/libxml2/ -DLIBXML2_LIB=/usr/lib/libxml2/ -DLOG4CPP_INC=/opt/log4cpp/include/ -DLOG4CPP_LIB=/opt/log4cpp/lib/ -DCMAKE_CXX_STANDARD=14 -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON
RUN make systematicstools
RUN make
RUN make install

ENV NUSYST /home/dunendprod/DUNE_ND_CAF/nusystematics/
ENV LD_LIBRARY_PATH ${NUSYST}/build/Linux/lib:${NUSYST}/build/nusystematics/artless:${LD_LIBRARY_PATH}

ENV LD_LIBRARY_PATH /opt/dk2nu/lib:/opt/genie/lib/:/opt/log4cpp/lib/:/opt/LHAPDF/lib/:/opt/pythia6428/:${LD_LIBRARY_PATH}

WORKDIR /home/dunendprod/DUNE_ND_CAF/
RUN sed -i 's|-I$(GENIE_INC)/GENIE|-I$(GENIE)/src|g' Makefile
RUN cat Makefile
RUN make
ENV PATH ${PATH}:/home/dunendprod/DUNE_ND_CAF/

WORKDIR /home/dunendprod/

ADD nusyst_inputs /home/dunendprod/nusyst_inputs
ADD *.gdml /home/dunendprod/
ADD *.xml /home/dunendprod/
ADD dune-nd.mac /home/dunendprod/dune-nd.mac
ADD fhicl.fcl /home/dunendprod/fhicl.fcl

ADD run_gevgen_edepsim_makeCAF_docker.sh /home/dunendprod/run_gevgen_edepsim_makeCAF_docker.sh

ENTRYPOINT ["bash", "/home/dunendprod/run_gevgen_edepsim_makeCAF_docker.sh"]
CMD []

