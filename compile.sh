#!/bin/bash -x

rm -rf coupler B C A
module load Intel
module load ParaStationMPI

mpif90 -g -cpp -o coupler coupler.f90
mpif90 -g -o B B.f90
mpif90 -g -o C C.f90
mpif90 -g -o A A.f90

