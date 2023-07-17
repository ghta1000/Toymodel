
!****************************************************************
!Toy coupled model to demonstrate MPI communicator concepts
!Author Ghazal Tashakor
!Email g.tashakor@fz-juelich.de
!****************************************************************

program B
  implicit none
  include 'mpif.h'

  integer :: ierr, rank, nprocs, color=3, key=2, PB
  integer :: coupler_rank, A_rank, C_rank, status(MPI_STATUS_SIZE), new_rank
  integer :: PB_nprocs, PB_size, nstep_PB=2, ii
  integer :: num_rows, num_cols, cart_comm, row_comm, col_comm
  integer :: cart_dims(2), cart_coords(2), row_rank, col_rank
  integer, dimension (:), allocatable :: PB_plist
  real(8), dimension (:,:), allocatable :: u_PB, u_A, u_C, u_B

  call MPI_INIT(ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD,nprocs,ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)

  call MPI_COMM_SPLIT(MPI_COMM_WORLD,color,key,PB,ierr)
  call MPI_COMM_RANK(PB,new_rank,ierr)
  call MPI_COMM_SIZE(PB,PB_nprocs,ierr)
  print *, 'PB : Global rank=', rank, 'Local rank=', new_rank

  ! Receiving coupler, A, and C ranks from coupler component
  call MPI_RECV(coupler_rank, 1, MPI_INT, MPI_ANY_SOURCE, 101, MPI_COMM_WORLD, status, ierr)
  call MPI_RECV(A_rank, 1, MPI_INT, MPI_ANY_SOURCE, 102, MPI_COMM_WORLD, status, ierr)
  call MPI_RECV(C_rank, 1, MPI_INT, MPI_ANY_SOURCE, 103, MPI_COMM_WORLD, status, ierr)

  ! Sending B num. procs and processor list to coupler
  if (new_rank == 0) then
    call MPI_SEND(PB_nprocs, 1, MPI_INT, coupler_rank, 104, MPI_COMM_WORLD, ierr)
    allocate(PB_plist(PB_nprocs))
  end if

  call MPI_GATHER(rank, 1, MPI_INT, PB_plist, 1, MPI_INT, 0, PB, ierr)

  if (new_rank == 0) then
    print *, 'PB: sending processor list to coupler'
    call MPI_SEND(PB_plist, PB_nprocs, MPI_INT, coupler_rank, 105, MPI_COMM_WORLD, ierr)
  end if

  call MPI_BARRIER(MPI_COMM_WORLD, ierr)

  ! 2D Decomposition in B component
  num_rows = 2
  num_cols = PB_nprocs / num_rows
  cart_dims(1) = num_rows
  cart_dims(2) = num_cols
  cart_coords(1) = new_rank / num_cols
  cart_coords(2) = new_rank - cart_coords(1) * num_cols
  cart_comm = MPI_COMM_WORLD
  call MPI_CART_CREATE(cart_comm, 2, cart_dims, .false., .false., PB, row_comm, ierr)
  call MPI_CART_SUB(row_comm, (/0, 1/), col_comm, ierr)
  call MPI_COMM_RANK(row_comm, row_rank, ierr)
  call MPI_COMM_RANK(col_comm, col_rank, ierr)
  PB_size = 190 * 384 / PB_nprocs

  allocate(u_B(190, 384))
  allocate(u_PB(190, PB_size))

  do ii = 1, nstep_PB
    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_A from A component
    if (new_rank == 0) then
      allocate(u_A(190, 384))
      call MPI_RECV(u_A, 190*384, MPI_DOUBLE_PRECISION, A_rank, 110, MPI_COMM_WORLD, status, ierr)
      print *, 'PB : received u_A from A'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    if (new_rank == 0) then
      print *, 'PB doing work'
      call sleep(1)
      print *, 'PB done with work'
      print *, 'PB : current time is', ii*3600, 'seconds'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Sending u_PB to coupler component
    call MPI_GATHER(u_B(:, PB_size*col_rank+1:PB_size*(col_rank+1)), 190*PB_size, MPI_DOUBLE_PRECISION, u_PB, 190*PB_size, MPI_DOUBLE_PRECISION, 0, col_comm, ierr)

    if (new_rank == 0) then
      call MPI_SEND(u_PB, 190*PB_size*num_cols, MPI_DOUBLE_PRECISION, coupler_rank, 112, MPI_COMM_WORLD, ierr)
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Receiving u_C from C component
    if (new_rank == 0) then
      allocate(u_C(190, 384))
      call MPI_RECV(u_C, 190*384, MPI_DOUBLE_PRECISION, C_rank, 111, MPI_COMM_WORLD, status, ierr)
      print *, 'PB : received u_C from C'
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)

    ! Sending u_PB to coupler component
    call MPI_GATHER(u_B(:, PB_size*col_rank+1:PB_size*(col_rank+1)), 190*PB_size, MPI_DOUBLE_PRECISION, u_PB, 190*PB_size, MPI_DOUBLE_PRECISION, 0, col_comm, ierr)

    if (new_rank == 0) then
      call MPI_SEND(u_PB, 190*PB_size*num_cols, MPI_DOUBLE_PRECISION, coupler_rank, 112, MPI_COMM_WORLD, ierr)
    end if

    call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  end do

  call MPI_FINALIZE(ierr)
end program
