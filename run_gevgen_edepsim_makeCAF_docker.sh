source scl_source enable devtoolset-6 

HORN=$1
FIRST=$2
NPER=$3
TEST=$4
if [ "${HORN}" != "FHC" ] && [ "${HORN}" != "RHC" ]; then
echo "Invalid beam mode ${HORN}"
echo "Must be FHC or RHC"
kill -INT $$
fi

MODE="neutrino"
RHC=""
if [ "${HORN}" = "RHC" ]; then
MODE="antineutrino"
RHC=" --rhc"
fi

if [ "${FIRST}" = "" ]; then
echo "First run number not specified, using 0"
FIRST=0
fi

CP="cp"
if [ "${TEST}" = "test" ]; then
echo "Test mode"
#CP="cp"
PROCESS=0
elif [[ $TEST =~ '^[0-9]+$' ]] ; then
    PROCESS=$TEST
    echo "PROCESS MANUALLY SET TO ${PROCESS}"
fi

echo "Running edepsim for ${HORN} mode, ${NPER} events"



RNDSEED=$((${PROCESS}+${FIRST}))

GEOMETRY="lar_mpt"
TOPVOL="volArgonCubeActive"
OUTFLAG="LAr"

cd /home/dunendprod/

# These are the internal container paths. A path on the host containing the inputs and space for the output must be mounted on these paths.
INPATH=/home/dunendprod/input
OUTPATH=/home/dunendprod/output
FLUXINFILENAMESTUB=gsimple

# gevgen
export GNUMIXML="GNuMIFlux.xml"
gevgen_fnal \
    -f ${INPATH}/${FLUXINFILENAMESTUB}*.root,DUNEND \
    -g ${GEOMETRY}.gdml \
    -t ${TOPVOL} \
    -m ${GEOMETRY}.${TOPVOL}.maxpl.xml \
    -L cm -D g_cm3 \
    --seed ${RNDSEED} \
    -n ${NPER} \
    -r ${RNDSEED} \
    -o ${OUTPATH}/${OUTFLAG}.${HORN} \
    --message-thresholds Messenger_production.xml \
    --cross-sections ${GENIEXSECPATH}/gxspl-FNALsmall.xml \
    --event-record-print-level 0 \
    --event-generator-list Default+CCMEC


gntpc -i ${OUTPATH}/${OUTFLAG}.${HORN}.${RNDSEED}.ghep.root -o ${OUTPATH}/${OUTFLAG}.${HORN}.${RNDSEED}.gtrac.root -f rootracker \
      --event-record-print-level 0 \
      --message-thresholds Messenger_production.xml

cp ${OUTPATH}/${OUTFLAG}.${HORN}.${RNDSEED}.gtrac.root input_file.gtrac.root

## Run edep-sim
edep-sim \
    -C \
    -g ${GEOMETRY}.gdml \
    -o ${OUTPATH}/edep.${RNDSEED}.root \
    -u \
    -e ${NPER} \
    dune-nd.mac

##################################################

# makeCAF expects ghep file to be genie.RUN.root
cp ${OUTPATH}/${OUTFLAG}.${HORN}.${RNDSEED}.ghep.root ${OUTPATH}/genie.${RNDSEED}.root

cd /home/dunendprod/DUNE_ND_CAF

source /opt/root/bin/thisroot.sh

## Run dumpTree
echo "Running dumpTree.py..."
python dumpTree.py --topdir ${OUTPATH} --first_run ${RNDSEED} --last_run ${RNDSEED} ${RHC} --grid --outfile ${OUTPATH}/${HORN}_${RNDSEED}.root

ln -s ${OUTPATH}/genie.${RNDSEED}.root .

## Run makeCAF
echo "Running makeCAF..."
./makeCAF --edepfile ${OUTPATH}/${HORN}_${RNDSEED}.root --ghepdir ${OUTPATH} --outfile ${OUTPATH}/CAF_${HORN}_${RNDSEED}.root --fhicl ~/fhicl.fcl --seed ${RNDSEED} ${RHC} --grid

echo "DONE!"

