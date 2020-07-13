--UPDATE
--ZMIANA LIMITU MIEJSC NA WARSZTACIE
create PROCEDURE update_workshop_participants_limit
	@WorkShopID int,
	@newLimit int
AS
BEGIN
	BEGIN TRY
	DECLARE @diff int
	set @diff = @newLimit - (SELECT Limit from Workshops where WorkShopID = @WorkShopID);
	
	IF dbo.funcWorkshopFreePlaces(@WorkShopID) < (-1 * @diff)
	BEGIN
		THROW 52000, 'There are too many registered participants to resize this workshop',1
	END
		
		UPDATE Workshops
		SET Limit = @newLimit
		where WorkShopID = @WorkShopID
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar(2048) 
		= 'cannot change limit: ' + ERROR_MESSAGE();
		;THROW 52000, @errorMsg,1
	END CATCH
END
go

--zmiana limitu dnia konferencji 
CREATE PROCEDURE update_conferenceday_participants_limit
	@ConferenceDayID int,
	@newLimit int
AS
	BEGIN
	DECLARE @diff int
	set @diff = @newLimit - (SELECT Limit from ConferenceDay where ConferenceDayID = @ConferenceDayID);
	
	IF dbo.funcConferenceDayFreePlaces(@ConferenceDayID) < (-1 * @diff)
	BEGIN
		THROW 52000, 'There are too many registered participants to resize this conferenceday',1
		END
		
		UPDATE ConferenceDay
		SET Limit = @newLimit
		where ConferenceDayID = @ConferenceDayID
	END
go
--unieważnianie nieopłaconych zamówień
create procedure cancel_reservations
as
BEGIN
	update Reservation
	set Reservation.isCancelled = 1
	from Reservation
		join Conferences as c
		on c.ConferenceID = Reservation.ConferenceID
	where Reservation.PaymentDate is  null 
	and DATEDIFF(dd,Reservation.ReservationDate,GETDATE()) > 7
END
go

--wprowadzanie daty płatności
create procedure proc_setPaymentDate
	@ReservationID INT,
	@PaymentDate DATE 
as 
BEGiN
	BEGIN TRY
	if not exists (select * from Reservation where ReservationID = @ReservationID)
	BEGIN
		THROW 52000, 'Reservation does not exist ', 1
	END

	if exists (select * from Reservation where ReservationID = @ReservationID and PaymentDate is not null)
	BEGIN
		THROW 52000, 'PaymentDate already exists ', 1
	END

	if exists (select * from Reservation where ReservationID = @ReservationID and isCancelled = 1)
	BEGIN
		THROW 52000, 'Reservation is cancelled ', 1
	END

	if DATEDIFF(dd, (select ReservationDate from Reservation where ReservationID = @ReservationID ), @PaymentDate) < 0 
	BEGIN
		THROW 52000, 'Wrong date', 1
	END
	
	update Reservation
	set Reservation.PaymentDate = @PaymentDate
	where Reservation.ReservationID = @ReservationID
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add payment date . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END
go
	
