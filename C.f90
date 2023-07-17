!****************************************************************
!Toy coupled model to demonstrate MPI communicator concepts
!Author Ghazal Tashakor
!Email g.tashakor@fz-juelich.de
!****************************************************************

program C
  implicit none
  include 'mpif.h'

  integer :: ierr, rank, nprocs, color=4, key=3, PC
  integer :: coupler_rank, B_rank, status(MPI_STATUS_SIZE), new_rank
  integer :: PC_nprocs, nstep_PC=2, ii
  integer, dimension (:), allocatable :: PC_plist
  real(8), dimension (:,:), allocatable :: u_PC, u_B

  call MPI_INIT(ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD,nprocs,ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)

  call MPI_COMM_SPLIT(MPI_COMM_WORLD,color,key,PC,ierr)
  call MPI_COMM_RANK(PC,new_rank,ierr)
  call MPI_COMM_SIZE(PC,PC_nprocs,ierr)
  print *, 'PC : Global rank=', rank, 'Local rank=', new_rank

  ! Receiving coupler and B ranks from coupler component
  call MPI_RECV(coupler_rank, 1, MPI_INT, MPI_ANY_SOURCE, 101, MPI_COMM_WORLD, status, ierr)
  call MPI_RECV(B_rank, 1, MPI_INT, MPI_ANY_SOURCE, 102, MPI_COMM_WORLD, status, ierr)

  ! Sending C num. procs and processor list to coupler
  if (new_rank == 0) then
    call MPI_SEND(PC_nprocs, 1, MPI_INT, coupler_rank, 106, MPI_COMM_WORLD, ierr)
    allocate(PC_plist(PC_nprocs))
  end if

  call MPI_GATHER(rank, 1, MPI_INT, PC_plist, 1, MPI_INT, 0, PC, ierr)

  if (new_rank == 0) then
    print *, 'PC: sending processor list to coupler'
    call MPI_SEND(PC_plist, PC_nprocs, MPI_INT, coupler_rank, 107, MPI_COMM_WORLD, ierr)
    call MPI_SEND(rank, 1, MPI_INT, coupler_rank, 110, MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    allocate(u_B(190, 384))
    call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
    print *, 'PC : received u_B from B'
  end if

  call MPI_BARRIER(MPI_COMM_WORLD, ierr)

  do ii = 2, nstep_PC
    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    if (new_rank == 0) then
      call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
      print *, 'PC : received u_B from B'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    if (new_rank == 0) then
      print *, 'PC doing work'
      call sleep(1)
      print *, 'PC done with work'
      print *, 'PC : current time is', ii*3600, 'seconds'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Sending u_PC to coupler component
    call MPI_SEND(u_PC, 190*384, MPI_DOUBLE_PRECISION, coupler_rank, 109, MPI_COMM_WORLD, ierr)

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    if (new_rank == 0) then
      call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
      print *, 'PC : received u_B from B'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  end do

  call MPI_FINALIZE(ierr)
end program
