!****************************************************************
!Toy coupled model to demonstrate MPI communicator concepts
!Author Ghazal Tashakor
!Email g.tashakor@fz-juelich.de
!****************************************************************

program Coupler
  implicit none
  include 'mpif.h'
  
  integer :: ierr, rank, nprocs, color=1, key=0
  integer :: PA_rank, PB_rank, PC_rank, PA_nprocs, PB_nprocs, PC_nprocs
  integer :: status(MPI_STATUS_SIZE)
  integer, dimension (:), allocatable :: PA_plist, PB_plist, PC_plist
  real(8), dimension (:,:), allocatable :: u_PC
  INTEGER :: cart_comm, row_comm, col_comm
  INTEGER :: num_rows, num_cols, cart_dims(2), cart_periodic(2)
  INTEGER :: cart_coords(2), row_rank, col_rank
  INTEGER :: ii ! Added declaration for 'ii'
  
  call MPI_INIT(ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD,nprocs,ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD,rank,ierr)
  
  ! Determine dimensions of the 2D decomposition
  num_rows = 2
  num_cols = nprocs / num_rows
  
  ! Create 2D Cartesian communicator
  cart_dims(1) = num_rows
  cart_dims(2) = num_cols
  cart_periodic(1) = .FALSE.
  cart_periodic(2) = .FALSE.
  call MPI_CART_CREATE(MPI_COMM_WORLD, 2, cart_dims, cart_periodic, .TRUE., cart_comm, ierr)
  
  ! Get coordinates and ranks in the 2D grid
  call MPI_CART_COORDS(cart_comm, rank, 2, cart_coords, ierr)
  call MPI_CART_RANK(cart_comm, cart_coords, row_rank, ierr)
  call MPI_CART_RANK(cart_comm, [cart_coords(2), cart_coords(1)], col_rank, ierr)
  
  if (row_rank == 0 .and. col_rank == 0) then
      print *, 'Coupler : Global rank=', rank, 'Local rank=', row_rank, col_rank
  end if
  
  ! Determine the ranks of PA, PB, and PC components
  PA_rank = 0
  PB_rank = num_rows
  PC_rank = nprocs - 1
  
  if (row_rank == 0 .and. col_rank == 0) then
      print *, 'Coupler : PA_rank=', PA_rank
      print *, 'Coupler : PB_rank=', PB_rank
      print *, 'Coupler : PC_rank=', PC_rank
  end if
  
  ! Sending coupler global rank to PA, PB, and PC components
  call MPI_SEND(rank, 1, MPI_INT, PA_rank, 101, MPI_COMM_WORLD, ierr)
  call MPI_SEND(rank, 1, MPI_INT, PB_rank, 101, MPI_COMM_WORLD, ierr)
  call MPI_SEND(rank, 1, MPI_INT, PC_rank, 101, MPI_COMM_WORLD, ierr)
  
  ! Receiving num. procs and processor lists from PA, PB, and PC components
  if (row_rank == 0 .and. col_rank == 0) then
      call MPI_RECV(PA_nprocs, 1, MPI_INT, PA_rank, 102, MPI_COMM_WORLD, status, ierr)
      call MPI_RECV(PB_nprocs, 1, MPI_INT, PB_rank, 102, MPI_COMM_WORLD, status, ierr)
      call MPI_RECV(PC_nprocs, 1, MPI_INT, PC_rank, 102, MPI_COMM_WORLD, status, ierr)
      allocate(PA_plist(PA_nprocs))
      allocate(PB_plist(PB_nprocs))
      allocate(PC_plist(PC_nprocs))
  end if
  
  call MPI_GATHER(rank, 1, MPI_INT, PA_plist, 1, MPI_INT, PA_rank, row_comm, ierr)
  call MPI_GATHER(rank, 1, MPI_INT, PB_plist, 1, MPI_INT, PB_rank, row_comm, ierr)
  call MPI_GATHER(rank, 1, MPI_INT, PC_plist, 1, MPI_INT, PC_rank, row_comm, ierr)
  
  if (row_rank == 0 .and. col_rank == 0) then
      print *, 'Coupler : received PA processor list'
      print *, 'Coupler : received PB processor list'
      print *, 'Coupler : received PC processor list'
      call MPI_RECV(PA_plist, PA_nprocs, MPI_INT, PA_rank, 103, MPI_COMM_WORLD, status, ierr)
      call MPI_RECV(PB_plist, PB_nprocs, MPI_INT, PB_rank, 103, MPI_COMM_WORLD, status, ierr)
      call MPI_RECV(PC_plist, PC_nprocs, MPI_INT, PC_rank, 103, MPI_COMM_WORLD, status, ierr)
  end if
  
  call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  
  if (row_rank == 0 .and. col_rank == 0) then
      ! Sending u_PC to PA component
      allocate(u_PC(190, 384))
      call random_seed()
      call random_number(u_PC)
      call MPI_SEND(u_PC, 190*384, MPI_DOUBLE_PRECISION, PA_rank, 109, MPI_COMM_WORLD, ierr)
      print *, 'Coupler : sending u_PC to PA'
  end if
  
  call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  
  do
      if (row_rank == 0 .and. col_rank == 0) then
          call MPI_RECV(u_PC, 190*384, MPI_DOUBLE_PRECISION, PC_rank, 109, MPI_COMM_WORLD, status, ierr)
          print *, 'Coupler : received u_PC from PC'
          call MPI_SEND(u_PC, 190*384, MPI_DOUBLE_PRECISION, PB_rank, 109, MPI_COMM_WORLD, ierr)
          print *, 'Coupler : sending u_PC to PB'
      end if
      
      if (row_rank == 0 .and. col_rank == 0) then
          call MPI_RECV(u_PC, 190*384, MPI_DOUBLE_PRECISION, PB_rank, 113, MPI_COMM_WORLD, status, ierr)
          print *, 'Coupler : received u_PB from PB'
          call MPI_SEND(u_PC, 190*384, MPI_DOUBLE_PRECISION, PC_rank, 113, MPI_COMM_WORLD, ierr)
          print *, 'Coupler : sending u_PB to PC'
      end if
      
      call MPI_BARRIER(MPI_COMM_WORLD, ierr)
      ! Other operations and communication between components
      
      if (row_rank == 0 .and. col_rank == 0) then
          print *, 'Coupler doing work'
          call sleep(1)
          print *, 'Coupler done with work'
      end if
      
      call MPI_BARRIER(MPI_COMM_WORLD, ierr)
      
      if (row_rank == 0 .and. col_rank == 0) then
          ii = ii + 1
          print *, 'Coupler : current time is', ii*3600, 'seconds'
      end if
      
      if (row_rank == 0 .and. col_rank == 0) then
          if (ii == 24) exit
      end if
      
      call MPI_BARRIER(MPI_COMM_WORLD, ierr)
      
      if (row_rank == 0 .and. col_rank == 0) then
          ii = ii + 1
      end if
      
      call MPI_BARRIER(MPI_COMM_WORLD, ierr)
  end do
  
  call MPI_FINALIZE(ierr)
end program
