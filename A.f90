!****************************************************************
!Toy coupled model to demonstrate MPI communicator concepts
!Author Ghazal Tashakor
!Email g.tashakor@fz-juelich.de
!****************************************************************

program A
  implicit none
  include 'mpif.h'

  integer :: ierr, rank, nprocs, color=2, key=1, PA
  integer :: coupler_rank, B_rank, status(MPI_STATUS_SIZE), new_rank
  integer :: PA_nprocs, nstep_PA=2, ii
  integer, dimension (:), allocatable :: PA_plist
  real(8), dimension (:,:), allocatable :: u_PA, u_B

  call MPI_INIT(ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD,nprocs,ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)

  call MPI_COMM_SPLIT(MPI_COMM_WORLD,color,key,PA,ierr)
  call MPI_COMM_RANK(PA,new_rank,ierr)
  call MPI_COMM_SIZE(PA,PA_nprocs,ierr)
  print *, 'PA : Global rank=', rank,'Local rank=', new_rank

  ! Receiving coupler and B ranks from coupler component
  call MPI_RECV(coupler_rank, 1, MPI_INT, MPI_ANY_SOURCE, 101, MPI_COMM_WORLD, status, ierr)
  call MPI_RECV(B_rank, 1, MPI_INT, MPI_ANY_SOURCE, 102, MPI_COMM_WORLD, status, ierr)

  ! Sending A num. procs and processor list to coupler
  if (new_rank == 0) then
    call MPI_SEND(PA_nprocs, 1, MPI_INT, coupler_rank, 106, MPI_COMM_WORLD, ierr)
    allocate(PA_plist(PA_nprocs))
  end if

  call MPI_GATHER(rank, 1, MPI_INT, PA_plist, 1, MPI_INT, 0, PA, ierr)

  if (new_rank == 0) then
    print *, 'PA: sending processor list to coupler'
    call MPI_SEND(PA_plist, PA_nprocs, MPI_INT, coupler_rank, 107, MPI_COMM_WORLD, ierr)
    call MPI_SEND(rank, 1, MPI_INT, coupler_rank, 110, MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    allocate(u_B(190, 384))
    call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
    print *, 'PA : received u_B from B'
  end if

  call MPI_BARRIER(MPI_COMM_WORLD, ierr)

  do ii = 2, nstep_PA
    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    if (new_rank == 0) then
      call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
      print *, 'PA : received u_B from B'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    if (new_rank == 0) then
      print *, 'PA doing work'
      call sleep(1)
      print *, 'PA done with work'
      print *, 'PA : current time is', ii*3600, 'seconds'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Sending u_PA to coupler component
    call MPI_SEND(u_PA, 190*384, MPI_DOUBLE_PRECISION, coupler_rank, 109, MPI_COMM_WORLD, ierr)

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_B from B component
    if (new_rank == 0) then
      call MPI_RECV(u_B, 190*384, MPI_DOUBLE_PRECISION, B_rank, 112, MPI_COMM_WORLD, status, ierr)
      print *, 'PA : received u_B from B'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  end do

  call MPI_FINALIZE(ierr)
end program
