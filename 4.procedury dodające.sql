--PROCEDURY
--dodające

--dodawanie ceny
CREATE PROCEDURE [dbo].[procAddPrice]
	@ConferenceID int,
	@Discount numeric(3,2),
	@UntilDays int
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	IF NOT EXISTS 
	(
	SELECT * FROM Conferences
	where ConferenceID = @ConferenceID
	)
	BEGIN
		;THROW 52000, 'Conference does not exist. ' ,1
	END
	INSERT INTO Price
	(
	ConferenceID,
	Discount,
	UntilDays
	)
	VALUES
	(
	@ConferenceID,
	@Discount,
	@UntilDays
	)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add conference day. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END
go
--nowa konferencja, dni konferencji
create procedure [dbo].[procAddConference]
	@Conf_name varchar(50),
	@Begin_date date,
	@End_date date,
	@Price money,
	@Student_disc numeric(3,2),
	@Limit int,
	@Disc numeric(3,2),
	@Until int
AS
BEGIN
	set nocount on
	begin transaction;
	BEGIN TRY
		IF (@Begin_date > @End_date or @Limit < 0 or @Disc <0 or @Disc >1 or @Student_disc < 0 or @Student_disc > 1)
			BEGIN 
				; throw 52000, 'Wrong data', 1
			END
		
		insert into Conferences(ConferenceName,BeginDate,EndDate,Price,StudentDiscount)
		values (@Conf_name,@Begin_date,@End_date,@Price,@Student_disc)
	IF @@ERROR <> 0
	begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
	end	
	
	declare @confID INT
	set @confID = @@IDENTITY
	declare @duration int
	declare @iterator int
	set @duration = DATEDIFF(dd, @Begin_date, @End_date)
	set @iterator = 0
	
	while @iterator <= @duration
	begin
		insert into ConferenceDay (ConferenceID, Date, Limit) values (@confID, cast(DATEADD(dd, @iterator, @Begin_date) as date),@Limit)
				
		IF @@ERROR <> 0 
		begin
			rollback transaction;
			RAISERROR('Error, transaction not completed!',16,-1)
		end
		if @iterator = 0
		begin 
			exec procAddPrice @ConferenceID=@confID, @Discount = @Disc, @UntilDays = @Until;
			IF @@ERROR <> 0
			begin
				RAISERROR('Error, transaction not completed!',16,-1)
				rollback transaction;
			end
		end
		set @iterator = @iterator + 1
	end
	commit transaction;
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add conference . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
		rollback transaction;
	END CATCH
END
GO
--TWORZENIE NOWEGO WARSZTATU

create procedure [dbo].[procAddWorkshop]
	@ConfDayID INT,
	@WorkshopName VARCHAR(50),
	@StartTime TIME(7),
	@EndTime TIME(7),
	@Price money,
	@WorkshopLimit INT
AS
BEGIN
	set nocount on
	BEGIN TRY
		IF NOT EXISTS 
			( select * from ConferenceDay where ConferenceDayID = @ConfDayID )
		BEGIN 
			THROW 52000, 'Conference day does not exist', 1
		END
		IF EXISTS 
			(select * from Workshops 
			 where WorkshopName = @WorkshopName and StartTime = @StartTime and EndTime = @EndTime)
		BEGIN
			THROW 52000, 'Such workshop already exists', 1
		END
		insert into Workshops (ConferenceDayID, WorkshopName, StartTime, EndTime, Price, Limit)
		values (@ConfDayID, @WorkshopName, @StartTime, @EndTime, @Price, @WorkshopLimit)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add workshop . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END 
GO



--nowy workshopbooking for company 
create PROCEDURE [dbo].[procAddWorkshopBookingCompany]
	@WorkshopID int,
	@ConferenceDayBookingID int,
	@StudentsNo int,
	@NormalNo int
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	begin transaction;
	IF NOT EXISTS
		(
		SELECT * FROM Workshops
		WHERE WorkShopID = @WorkShopID
		)
	BEGIN
		;THROW 52000, 'Workshop does not exist. ' ,1
	END
	IF NOT EXISTS
		(
		SELECT * FROM ConferenceDayBooking
		WHERE  ConferenceDayBookingID = @ConferenceDayBookingID
		)
	BEGIN
		;THROW 52000, 'ConferenceDayBooking does not exist. ' ,1
	END
	IF (@StudentsNo + @NormalNo = 0) or @StudentsNo < 0 or @NormalNo < 0 
	BEGIN
		;THROW 52000, 'Not acceptable tickets values ' ,1	
	END
	
	if (select ConferenceDayID from ConferenceDayBooking where @ConferenceDayBookingID = ConferenceDayBookingID) <> (select ConferenceDayID from Workshops where @WorkshopID = WorkshopID)
	BEGIN
		;THROW 52000, 'Workshop does not belong to that conference day' ,1	
	END
	
	INSERT INTO WorkshopBooking
		(
		WorkShopID,
		ConferenceDayBookingID,
		NormalTickets,
		ConcessionaryTickets,
		isCancelled
		)
	VALUES
		(
		@WorkshopID,
		@ConferenceDayBookingID,
		@StudentsNo,
		@NormalNo,
		0
		)
	commit transaction;
	END TRY
	BEGIN CATCH
		rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add conference day. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO
-- indywidualna rezerwacja na warsztat
CREATE PROCEDURE [dbo].[procAddWorkshopBookingIndividual]
	@WorkshopID int,
	@ConferenceDayBookingID int,
	@StudentCard varchar(10) = null
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		begin transaction;
	IF NOT EXISTS
		(
		SELECT * FROM Workshops
		WHERE WorkShopID = @WorkShopID
		)
	BEGIN
		;THROW 52000, 'Workshop does not exist. ' ,1
	END
	IF NOT EXISTS
		(
		SELECT * FROM ConferenceDayBooking
		WHERE  ConferenceDayBookingID = @ConferenceDayBookingID
		)
	BEGIN
		;THROW 52000, 'ConferenceDayBooking does not exist. ' ,1
	END
	if @StudentCard is not null and not exists (select *
	from Reservation as r
		left join Client as c on c.ClientID = r.ClientID
		left join IndividualClients as ic on ic.ClientID = c.ClientID
		left join PersonalData as pd on pd.PersonalDataID = ic.PersonalDataID
		where @StudentCard = pd.StudentCard)
	BEGIN 
	THROW 52000, 'Student Card does not exists', 1
	END
	if (select ConferenceDayID from ConferenceDayBooking where @ConferenceDayBookingID = ConferenceDayBookingID) <> (select ConferenceDayID from Workshops where @WorkshopID = WorkshopID)
	BEGIN
		;THROW 52000, 'Workshop does not belong to that conference day' ,1	
	END
	if @StudentCard is not null
	BEGIN
		insert into WorkshopBooking (WorkshopID,ConferenceDayBookingID, NormalTickets, ConcessionaryTickets, isCancelled)
		values ( @WorkshopID, @ConferenceDayBookingID, 0, 1, 0)
	END 
	if @StudentCard is null
	BEGIN
		insert into WorkshopBooking (WorkshopID,ConferenceDayBookingID, NormalTickets, ConcessionaryTickets, isCancelled)
		values ( @WorkshopID, @ConferenceDayBookingID, 1, 0, 0)
	END 
		commit transaction;
	END TRY
	BEGIN CATCH
		rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add conference day. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO
--rezerwacja indywidualna
CREATE PROCEDURE [dbo].[procAddReservationIndividual]
	@ClientID int,
	@ConferenceID int,
	@ReservationDate date,
	@PaymentDate date,
	@isCancelled bit = 0,
	@Value money
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	IF NOT EXISTS 
	(
	SELECT * FROM Client
	WHERE ClientID = @ClientID
	)
	BEGIN
		;THROW 52000, 'Client does not exist. ' ,1
	END
	IF NOT EXISTS 
	(
	SELECT * FROM IndividualClients as ic
	WHERE ic.ClientID = @ClientID
	)
	BEGIN
		;THROW 52000, 'Client is not individual person. ' ,1
	END
	IF NOT EXISTS 
	(
	SELECT * FROM Conferences
	WHERE ConferenceID = @ConferenceID
	)
	BEGIN
		;THROW 52000, 'Conference does not exist. ' ,1
	END
	INSERT INTO Reservation
		(
		ClientID,
		ConferenceID,
		ReservationDate,
		PaymentDate,
		isCancelled,
		Value
		)
		VALUES
		(
		@ClientID,
		@ConferenceID,
		@ReservationDate,
		@PaymentDate,
		@isCancelled,
		@Value
		)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add conference day. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO		
--rezerwacja firmowa
CREATE PROCEDURE [dbo].[procAddReservationCompany]
	@ClientID int,
	@ConferenceID int,
	@ReservationDate date,
	@PaymentDate date,
	@isCancelled bit = 0,
	@Value money
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
	IF NOT EXISTS 
	(
	SELECT * FROM Client
	WHERE ClientID = @ClientID
	)
	BEGIN
		;THROW 52000, 'Client does not exist. ' ,1
	END
	IF NOT EXISTS 
	(
	SELECT * FROM Company as c
	WHERE c.ClientID = @ClientID
	)
	BEGIN
		;THROW 52000, 'Client is not company. ' ,1
	END
	IF NOT EXISTS 
	(
	SELECT * FROM Conferences
	WHERE ConferenceID = @ConferenceID
	)
	BEGIN
		;THROW 52000, 'Conference does not exist. ' ,1
	END
	INSERT INTO Reservation
		(
		ClientID,
		ConferenceID,
		ReservationDate,
		PaymentDate,
		isCancelled,
		Value
		)
		VALUES
		(
		@ClientID,
		@ConferenceID,
		@ReservationDate,
		@PaymentDate,
		@isCancelled,
		@Value
		)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add conference day. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END		
GO
--dodawanie danych personalnych
create procedure [dbo].[procAddPerson]
	@FirstName varchar(30),
	@LastName varchar(30),
	@Email varchar(30),
	@Phone varchar(9),
	@StudentCard varchar (10) = null
as
begin
	set nocount on;
	begin try
	begin transaction;
	if exists
	(
	select * from PersonalData
	where Email=@Email or Phone=@Phone
	)
	BEGIN
			; THROW 52000, 'Participant already exists.',1
		END
	insert into
	PersonalData
	(
	FirstName,
	LastName,
	Email,
	Phone,
	StudentCard
	)
	values
	(
	@FirstName,
	@LastName,
	@Email,
	@Phone,
	@StudentCard
	)
	commit transaction;
	end try
	BEGIN CATCH
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add Person. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO

--dodawanie klienta firmowego
create procedure [dbo].[procAddCompanyClient]
	@ContactName varchar(20),
	@City varchar(30),
	@Street varchar(30),
	@HomePage varchar(30) = null,
	@Country varchar(30),
	@Email varchar(30),
	@Phone varchar(9),
	@CompanyName varchar(30)
AS
BEGIN 
	set nocount on 
	BEGIN TRY
	begin transaction;
	IF EXISTS 
		(select * from Client where ContactName = @ContactName) or EXISTS 
		(select * from Company 
		 where City = @City and Street = @Street and Email = @Email 
			and Country = @Country and Phone = @Phone and CompanyName = @CompanyName)
	BEGIN 
		THROW 52000, 'Client/Company already exist', 1
	END
	
	declare @tempID INT
	
	insert into Client( ContactName )
	values (@ContactName)
	IF @@ERROR <> 0 
		begin
			rollback transaction;
			RAISERROR('Error, transaction not completed!',16,-1)
		end
	set @tempID = @@IDENTITY
	
	if exists (select * from Company where Email = @Email or Phone = @Phone or CompanyName = @CompanyName)
	BEGIN 
		THROW 52000, 'Client/Company already exist', 1
	END
	
	if @Email not like '%@%' or LEN(@Phone) <> 9 or ISNUMERIC(@Phone) <> 1
	BEGIN 
		THROW 52000, 'wrong data', 1
	END
	insert into Company(ClientID, City, Street, HomePage, Country, Email, Phone, CompanyName)
	values (@tempID, @City, @Street, @HomePage, @Country, @Email, @Phone, @CompanyName)
	commit transaction;
	END TRY
	BEGIN CATCH
	rollback transaction;
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add Company Client . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END
GO
--dodawanie klienta indywidualnego

create procedure [dbo].[procAddIndividualClient]
	@ContactName varchar (20),
	@FirstName varchar(30),
	@LastName varchar(30),
	@Email varchar(30),
	@Phone varchar(9),
	@StudentCard varchar (10) = null
as
begin
	set nocount on;
	begin try
	begin transaction; 
	if  exists
		(select * from PersonalData
		where Email=@Email or Phone=@Phone or @StudentCard = StudentCard)
	BEGIN
		; THROW 52000, 'Person already exists.',1
	END
	
	if @Email not like '%@%' or LEN(@Phone) <> 9 or ISNUMERIC(@Phone) <> 1
	BEGIN 
		THROW 52000, 'wrong data', 1
	END
	
	if exists (select * from Client where ContactName = @ContactName)
	BEGIN
		; THROW 52000, 'Client already exists.',1
	END
	insert into Client(ContactName) values (@ContactName)
	IF @@ERROR <> 0
	begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
	end
	declare @ClientID int
	set @ClientID = @@IDENTITY

	exec procAddPerson  @FirstName, @LastName, @Email, @Phone, @StudentCard
	IF @@ERROR <> 0
	begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
	end
	declare @id int = @@IDENTITY
	insert into IndividualClients(PersonalDataID, ClientID) values (@id, @ClientID)
	IF @@ERROR <> 0
	begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
	end
	commit transaction;
	end try
	BEGIN CATCH
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add IndividualClient. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO
--dodawanie pracownika

create procedure procAddEmployee
	@firstName varchar(30),
	@lastName varchar(30),
	@Email varchar(30),
	@Phone varchar(9),
	@CompID int,
	@StudentCard varchar(10) = null
as
begin
	set nocount on
	begin try
		begin transaction
		if exists (select * from PersonalData where Email = @Email and Phone = @Phone and @firstName = FirstName and @lastName = LastName)
		begin
			THROW 52000, 'Employee Data already exists', 1
		end

		declare @empID int
		exec dbo.procAddPerson @firstName, @lastName, @Email,@Phone, @StudentCard

		IF @@ERROR <> 0
		begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
		end

		set @empID = @@IDENTITY
		insert into Employees (CompanyID, PersonalDataID) values (@CompID, @empID)

		IF @@ERROR <> 0
		begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
		end

		commit transaction;
	end try
	begin CATCH
	rollback transaction;
	declare @errorMsg nvarchar (2048)
			= 'Cannot add Company Client . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	end CATCH
end
GO
	--dodawanie bookingu dnia konferencji (indywidualny klient)
create procedure procAddConferenceDayBookingIndividual
	@ConferenceDayID INT,
	@ReservationID INT,
	@StudentCard varchar(10) =  null
as
BEGIN 
	BEGIN TRY
	SET NOCOUNT ON
	begin transaction;
	if NOT EXISTS
		(select * from ConferenceDay where ConferenceDayID = @ConferenceDayID)
	BEGIN 
	THROW 52000, 'Conference day does not exists ', 1
	END
	if NOT EXISTS
		(select * from Reservation where ReservationID = @ReservationID)
	BEGIN 
	THROW 52000, 'Reservation does not exists ', 1
	END
	if (select ConferenceID from Reservation where ReservationID = @ReservationID )<> (select ConferenceID from ConferenceDay where ConferenceDayID = @ConferenceDayID )
	BEGIN 
	THROW 52000, 'Diffrenct conference is reserved', 1
	END
	if @StudentCard is not null and not exists (select *
	from Reservation as r
		left join Client as c on c.ClientID = r.ClientID
		left join IndividualClients as ic on ic.ClientID = c.ClientID
		left join PersonalData as pd on pd.PersonalDataID = ic.PersonalDataID
		where @StudentCard = pd.StudentCard)
	BEGIN 
	THROW 52000, 'Student Card does not exists', 1
	END
	if @StudentCard is not null
	BEGIN
		insert into ConferenceDayBooking (ConferenceDayID, ReservationID, NormalTickets, ConcessionaryTickets, isCancelled)
		values ( @ConferenceDayID, @ReservationID, 0, 1, 0)
	END 
	if @StudentCard is null
	BEGIN
		insert into ConferenceDayBooking (ConferenceDayID, ReservationID, NormalTickets, ConcessionaryTickets, isCancelled)
		values ( @ConferenceDayID, @ReservationID, 1, 0, 0)
	END 
	commit transaction;
	END TRY
	BEGIN CATCH
	rollback transaction;
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add Conference day booking . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END
GO
--dodawanie bookingu firmy na dzień konferencji
create procedure procAddConferenceDayBookingCompany
	@ConferenceDayID INT,
	@ReservationID INT,
	@NormalTickets INT,
	@ConcessionaryTickets INT
as
BEGIN 
	BEGIN TRY
	SET NOCOUNT ON
	begin transaction;
	
	if NOT EXISTS
		(select * from ConferenceDay where ConferenceDayID = @ConferenceDayID)
	BEGIN 
	THROW 52000, 'Conference day does not exists ', 1
	END
	
	if (select ConferenceID from Reservation where ReservationID = @ReservationID )<> (select ConferenceID from ConferenceDay where ConferenceDayID = @ConferenceDayID )
	BEGIN 
	THROW 52000, 'Diffrenct conference is reserved', 1
	END
	
	if NOT EXISTS
		(select * from Reservation where ReservationID = @ReservationID)
	BEGIN 
	THROW 52000, 'Reservation does not exists ', 1
	END
	
	IF (@NormalTickets + @ConcessionaryTickets = 0) or @ConcessionaryTickets < 0 or @NormalTickets < 0 
	BEGIN
		;THROW 52000, 'Not acceptable tickets values ' ,1	
	END
	
	insert into ConferenceDayBooking (ConferenceDayID, ReservationID, NormalTickets, ConcessionaryTickets, isCancelled)
	values (@ConferenceDayID, @ReservationID, @NormalTickets, @ConcessionaryTickets, 0)
	
	commit transaction;
	END TRY
	BEGIN CATCH
	rollback transaction;
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add Conference day booking . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END
GO
--Dodaj indywidualnego członka konferencji
create procedure [dbo].[procAddConferenceIndividualParticipant]
	@ConferenceDayBookingID int,
	@FirstName varchar(30),
	@LastName varchar (30),
	@Email varchar (30),
	@Phone varchar (9)
as
begin	
set nocount on
begin try
	begin transaction;
	if not exists (select * from PersonalData where FirstName = @FirstName and LastName =@LastName and Email =  @Email and @Phone= Phone  )
	begin
	; throw 52000, 'Given Person does not exist ',1
	end
	if not exists ( select * from ConferenceDayBooking where ConferenceDayBookingID = @ConferenceDayBookingID)
	begin
	; throw 52000, 'Wrong ConferenceDayBookingID. ConferenceDayBookingID does not exist ',1
	end
	declare @PersonalDataID int = (select PersonalDataID from PersonalData where FirstName = @FirstName and LastName = @LastName and Email = @Email and Phone = @Phone)
	if not exists ( select * from IndividualClients where PersonalDataID = @PersonalDataID)
	begin
	; throw 52000, 'This person is not IndividualClient ',1
	end
	insert into Participants(ConferenceDayBookingID, PersonalDataID)
	values (@ConferenceDayBookingID, @PersonalDataID)
	commit transaction;
	end try
	begin catch
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add ConferenceIndividualParticipant. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO	
	

--Dodaj firmowego Uczestika konferencji
create procedure [dbo].[procAddConferenceCompanyParticipant]
	@ConferenceDayBookingID int,
	@FirstName varchar(30),
	@LastName varchar (30),
	@Email varchar (30),
	@Phone varchar (9),
	@CompanyID int,
	@StudentCard varchar(10) = null
as
begin	
set nocount on;
begin try
begin transaction;
	if not exists ( select * from ConferenceDayBooking where ConferenceDayBookingID = @ConferenceDayBookingID)
	begin
		; throw 52000, 'Wrong ConferenceDayBookingID. ConferenceDayBookingID does not exist ',1
	end
	if exists (select * from PersonalData where FirstName = @FirstName and LastName = @LastName and  Email = @Email and Phone = @Phone)
	begin
		declare @PersonalDataID int = (select PersonalDataID from PersonalData where FirstName = @FirstName and LastName = @LastName and  Email = @Email and Phone = @Phone)
		if exists (select * from Employees where PersonalDataID=@PersonalDataID and CompanyID = @CompanyID)
		begin
			insert into Participants (ConferenceDayBookingID, PersonalDataID)
			values (@ConferenceDayBookingID, @PersonalDataID)
		end
	end
if not exists (select * from PersonalData where FirstName = @FirstName and LastName = @LastName and  Email = @Email and Phone = @Phone)
	begin
	exec procAddPerson @FirstName, @LastName, @Email, @Phone, @StudentCard
	IF @@ERROR <> 0
		begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
		end
	declare @PDataID int  = @@Identity
	insert into Employees (CompanyID, PersonalDataID) values (@CompanyID, @PDataID)
	IF @@ERROR <> 0
		begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
		end
	insert into Participants (ConferenceDayBookingID, PersonalDataID) values (@ConferenceDayBookingID, @PDataID)
	IF @@ERROR <> 0
		begin
		RAISERROR('Error, transaction not completed!',16,-1)
		rollback transaction;
		end
	end
	commit transaction;
	end try
	begin catch
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add ConferenceCompanyParticipant. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO
-- Dodaj firmowego uczestnika warsztatów

 create procedure [dbo].[procAddWorkshopCompanyParticipant]
	@ParticipantID int,
	@WorkshopBookingID int
as
begin
set nocount on;
begin try
begin transaction;
	if not exists ( select * from Participants where ParticipantID = @ParticipantID)
	begin
		; throw 52000, 'Wrong ParticipantID. ParticipantID does not exist ',1
	end
	if not exists ( select * from WorkshopBooking where WorkshopBookingID = @WorkshopBookingID)
	begin
		; throw 52000, 'Wrong WorkshopBookingID. WorkshopBookingID does not exist ',1
	end
	if (select ConferenceDayBookingID from Participants where ParticipantID = @ParticipantID) <>
	   (select ConferenceDayBookingID from WorkshopBooking where WorkshopBookingID = @WorkshopBookingID)
	begin
		; throw 52000, 'Participant can not take part in this workshop (wrong conferencedaybookingid) ',1
	end
		insert into WorkshopParticipants(ParticipantID, WorkshopBookingID)
		values (@ParticipantID, @WorkshopBookingID)
commit transaction;
	end try
	begin catch
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add WorkshopParticipant. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	
GO
--Dodaj uczestnika warsztatów	
create procedure [dbo].[proccAddWorkshopIndividualParticipant]
	@ParticipantID int,
	@WorkshopBookingID int 
as
begin
set nocount on;
begin try
begin transaction;
	if not exists ( select * from Participants where ParticipantID = @ParticipantID)
	begin
		; throw 52000, 'Wrong ParticipantID. ParticipantID does not exist ',1
	end
	if not exists ( select * from WorkshopBooking where WorkshopBookingID = @WorkshopBookingID)
	begin
		; throw 52000, 'Wrong WorkshopBookingID. WorkshopBookingID does not exist ',1
	end
	if not exists (	select * from IndividualClients as ic
					where ic.PersonalDataID = (select PersonalDataID from Participants where ParticipantID = @ParticipantID))
	begin
		; throw 52000, 'Participant is not individual client ',1
	end
	if (select ConferenceDayBookingID from Participants where ParticipantID = @ParticipantID) <> 
	   (select ConferenceDayBookingID from WorkshopBooking where WorkshopBookingID = @WorkshopBookingID)
	begin
		; throw 52000, 'Participant can not take part in this workshop (wrong conferencedaybookingid) ',1
	end
	insert into WorkshopParticipants(ParticipantID, WorkshopBookingID)
	values (@ParticipantID, @WorkshopBookingID)
	commit transaction;
	end try
	begin catch
	rollback transaction;
		DECLARE @errorMsg nvarchar(2048) 
		= 'Can not add WorkshopParticipant. Error message: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END	

GO




	
	




