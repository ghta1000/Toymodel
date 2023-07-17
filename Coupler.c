!****************************************************************
!Toy coupled model to demonstrate MPI communicator concepts
!Author Ghazal Tashakor
!Email g.tashakor@fz-juelich.de
!****************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

int main(int argc, char* argv[]) {
    int rank, nprocs, PA_rank, PB_rank, PC_rank, PA_nprocs, PB_nprocs, PC_nprocs;
    MPI_Status status;

    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    // Determine the ranks of PA, PB, and PC components
    PA_rank = 0;
    PB_rank = 1;
    PC_rank = 2;

    int num_iterations = 10; // Number of loop iterations

    for (int iteration = 0; iteration < num_iterations; iteration++) {
        if (rank == PA_rank) {
            // PA component

            // Receiving num. procs from coupler
            MPI_Recv(&PA_nprocs, 1, MPI_INT, PA_rank, 102, MPI_COMM_WORLD, &status);

            // Sending processor list to coupler
            int* PA_plist = (int*)malloc(PA_nprocs * sizeof(int));
            MPI_Gather(&rank, 1, MPI_INT, PA_plist, 1, MPI_INT, PA_rank, MPI_COMM_WORLD);
            MPI_Send(PA_plist, PA_nprocs, MPI_INT, PA_rank, 103, MPI_COMM_WORLD);

            // Receiving u_PC from coupler
            int u_PC_rows = 10; // Replace with the actual number of rows for u_PC
            int u_PC_cols = 10; // Replace with the actual number of columns for u_PC
            double** u_PC = (double**)malloc(u_PC_rows * sizeof(double*));
            for (int i = 0; i < u_PC_rows; i++) {
                u_PC[i] = (double*)malloc(u_PC_cols * sizeof(double));
            }
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PA_rank, 109, MPI_COMM_WORLD, &status);

            // Perform PA computations
            printf("Iteration %d, Rank %d: Performing PA computations\n", iteration, rank);

            // Sending u_PA to coupler
            MPI_Send(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PA_rank, 110, MPI_COMM_WORLD);

            // Cleanup
            for (int i = 0; i < u_PC_rows; i++) {
                free(u_PC[i]);
            }
            free(u_PC);
            free(PA_plist);
        }
        else if (rank == PB_rank) {
            // PB component

            // Receiving num. procs from coupler
            MPI_Recv(&PB_nprocs, 1, MPI_INT, PB_rank, 102, MPI_COMM_WORLD, &status);

            // Sending processor list to coupler
            int* PB_plist = (int*)malloc(PB_nprocs * sizeof(int));
            MPI_Gather(&rank, 1, MPI_INT, PB_plist, 1, MPI_INT, PB_rank, MPI_COMM_WORLD);
            MPI_Send(PB_plist, PB_nprocs, MPI_INT, PB_rank, 103, MPI_COMM_WORLD);

            // Receiving u_PC from coupler
            int u_PC_rows = 10; // Replace with the actual number of rows for u_PC
            int u_PC_cols = 10; // Replace with the actual number of columns for u_PC
            double** u_PC = (double**)malloc(u_PC_rows * sizeof(double*));
            for (int i = 0; i < u_PC_rows; i++) {
                u_PC[i] = (double*)malloc(u_PC_cols * sizeof(double));
            }
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PB_rank, 113, MPI_COMM_WORLD, &status);

            // Perform PB computations
            printf("Iteration %d, Rank %d: Performing PB computations\n", iteration, rank);

            // Sending u_PB to coupler
            MPI_Send(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PB_rank, 114, MPI_COMM_WORLD);

            // Cleanup
            for (int i = 0; i < u_PC_rows; i++) {
                free(u_PC[i]);
            }
            free(u_PC);
            free(PB_plist);
        }
        else if (rank == PC_rank) {
            // PC component

            // Receiving num. procs from coupler
            MPI_Recv(&PC_nprocs, 1, MPI_INT, PC_rank, 102, MPI_COMM_WORLD, &status);

            // Sending processor list to coupler
            int* PC_plist = (int*)malloc(PC_nprocs * sizeof(int));
            MPI_Gather(&rank, 1, MPI_INT, PC_plist, 1, MPI_INT, PC_rank, MPI_COMM_WORLD);
            MPI_Send(PC_plist, PC_nprocs, MPI_INT, PC_rank, 103, MPI_COMM_WORLD);

            // Receiving u_PA from PA component
            int u_PC_rows = 10; // Replace with the actual number of rows for u_PC
            int u_PC_cols = 10; // Replace with the actual number of columns for u_PC
            double** u_PC = (double**)malloc(u_PC_rows * sizeof(double*));
            for (int i = 0; i < u_PC_rows; i++) {
                u_PC[i] = (double*)malloc(u_PC_cols * sizeof(double));
            }
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PC_plist[PA_rank], 110, MPI_COMM_WORLD, &status);

            // Perform PC computations
            printf("Iteration %d, Rank %d: Performing PC computations\n", iteration, rank);

            // Sending u_PC to coupler
            MPI_Send(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PC_rank, 111, MPI_COMM_WORLD);

            // Cleanup
            for (int i = 0; i < u_PC_rows; i++) {
                free(u_PC[i]);
            }
            free(u_PC);
            free(PC_plist);
        }
        else {
            // Coupler component

            // Sending num. procs to PA, PB, and PC components
            PA_nprocs = 1; // Set the number of procs for PA component
            PB_nprocs = 1; // Set the number of procs for PB component
            PC_nprocs = 1; // Set the number of procs for PC component

            MPI_Send(&PA_nprocs, 1, MPI_INT, PA_rank, 102, MPI_COMM_WORLD);
            MPI_Send(&PB_nprocs, 1, MPI_INT, PB_rank, 102, MPI_COMM_WORLD);
            MPI_Send(&PC_nprocs, 1, MPI_INT, PC_rank, 102, MPI_COMM_WORLD);

            // Receiving processor lists from PA, PB, and PC components
            int* PA_plist = (int*)malloc(PA_nprocs * sizeof(int));
            int* PB_plist = (int*)malloc(PB_nprocs * sizeof(int));
            int* PC_plist = (int*)malloc(PC_nprocs * sizeof(int));
            MPI_Gather(&rank, 1, MPI_INT, PA_plist, 1, MPI_INT, PA_rank, MPI_COMM_WORLD);
            MPI_Gather(&rank, 1, MPI_INT, PB_plist, 1, MPI_INT, PB_rank, MPI_COMM_WORLD);
            MPI_Gather(&rank, 1, MPI_INT, PC_plist, 1, MPI_INT, PC_rank, MPI_COMM_WORLD);
            MPI_Send(PA_plist, PA_nprocs, MPI_INT, PA_rank, 103, MPI_COMM_WORLD);
            MPI_Send(PB_plist, PB_nprocs, MPI_INT, PB_rank, 103, MPI_COMM_WORLD);
            MPI_Send(PC_plist, PC_nprocs, MPI_INT, PC_rank, 103, MPI_COMM_WORLD);

            // Receiving u_PA from PA component
            int u_PC_rows = 10; // Replace with the actual number of rows for u_PC
            int u_PC_cols = 10; // Replace with the actual number of columns for u_PC
            double** u_PC = (double**)malloc(u_PC_rows * sizeof(double*));
            for (int i = 0; i < u_PC_rows; i++) {
                u_PC[i] = (double*)malloc(u_PC_cols * sizeof(double));
            }
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PA_rank, 109, MPI_COMM_WORLD, &status);

            // Sending u_PC to PC component
            MPI_Send(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PC_rank, 109, MPI_COMM_WORLD);

            // Receiving u_PB from PB component
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PB_rank, 113, MPI_COMM_WORLD, &status);

            // Sending u_PC to PB component
            MPI_Send(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PB_rank, 113, MPI_COMM_WORLD);

            // Receiving u_PC from PC component
            MPI_Recv(&(u_PC[0][0]), u_PC_rows * u_PC_cols, MPI_DOUBLE, PC_rank, 111, MPI_COMM_WORLD, &status);

            // Cleanup
            for (int i = 0; i < u_PC_rows; i++) {
                free(u_PC[i]);
            }
            free(u_PC);
            free(PA_plist);
            free(PB_plist);
            free(PC_plist);
        }
    }

    MPI_Finalize();
    return 0;
}
