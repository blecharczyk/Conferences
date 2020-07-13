-- trigger / czy liczba studentow zapowiedzianych zgadza sie z rzeczywistą przy pelnym wypelnieniu uczestnikow dla zadanej rezerwacji

create trigger appropriate_students_amount
 on Participants
 after insert, update
 as
 begin 
	
	if exists
	(
	select * 
	from Inserted as p
		join PersonalData as pd
		on pd.PersonalDataID = p.PersonalDataID
		join ConferenceDayBooking as cdb
		on cdb.ConferenceDayBookingID = p.ConferenceDayBookingID
	group by pd.PersonalDataID, cdb.ConcessionaryTickets, cdb.NormalTickets
	having cdb.ConcessionaryTickets != (select count(pd_inner.PersonalDataID) 
										from PersonalData as pd_inner 
										where pd.PersonalDataID = pd_inner.PersonalDataID and pd_inner.StudentCard is not null)
			and (cdb.ConcessionaryTickets+cdb.NormalTickets) = (select count(pd_inner.PersonalDataID) 
										from PersonalData as pd_inner 
										where pd.PersonalDataID = pd_inner.PersonalDataID)
	)
	BEGIN
		THROW 50001 , 'Number of students is not equal to declared number of students in booking ' , 1
		ROLLBACK TRANSACTION
	END
end
GO

--mniej zapisanych na warsztat niż na konferencję

create TRIGGER  [dbo].[workshop_participants_fewer_than_day_participants_trigger]
    ON [dbo].[WorkshopBooking]
    AFTER INSERT, UPDATE
AS
    BEGIN
        IF EXISTS(
            SELECT *
            FROM inserted as i
            JOIN ConferenceDayBooking as cdb
            ON cdb.ConferenceDayBookingID=i.ConferenceDayBookingID
            WHERE (i.NormalTickets+i.ConcessionaryTickets)>(cdb.NormalTickets+cdb.ConcessionaryTickets)
        )
        BEGIN
            THROW 50001, 'All workshop participants must be day attendees', 1
        END
    END
GO


--sprawdzenie czy w dniu konferencji jest wiekszy limit na uczestnikow niz na warsztatach (bo każdy uczestnik warsztatu musi byc zapisany na ten dzien!!!


create trigger appropriate_limits
on Workshops
after insert, update
as
begin 
	if exists
	(
		select * 
		from Inserted as i
			join ConferenceDay as cd
			on cd.ConferenceDayID = i.ConferenceDayID
		where i.Limit > cd.Limit 
	)
	begin 
		THROW 50001 , 'Workshop cannot have greater limit of participant`s amount than conference day than ' , 1
		ROLLBACK TRANSACTION
	end
END
GO
--sprawdzenie, czy przypadkiem liczba zarejestrowanych na wartsztat nie jest wieksza niz zarejestrowanych na dzien konferencji 

create trigger workshop_participants_conf_participants
on WorkshopBooking
after insert, update
as
begin
	if exists
	(
		select * 
		from Inserted as i
			join ConferenceDayBooking as cdb 
			on cdb.ConferenceDayBookingID = i.ConferenceDayBookingID
		where (i.ConcessionaryTickets + i.NormalTickets) > (cdb.ConcessionaryTickets + cdb.NormalTickets)
	)
	begin 
		THROW 50001 , 'There cannot be more participants on workshop than conference day' , 1
		ROLLBACK TRANSACTION
	end
end
GO
-- sprawdzenie, czy w jednym zamowieniu na pewno są ujęte dni rezerwacji na dany dzien konferencji

create trigger conf_days_in_one_conf
on ConferenceDayBooking
after insert
as
begin
	if exists
	(
		select *
		from Inserted as i
			join Reservation as r
			on r.ReservationID = i.ReservationID
			join ConferenceDay as cd
			on cd.ConferenceDayID = i.ConferenceDayID
			join Conferences as c1
			on c1.ConferenceID = cd.ConferenceID
			join Conferences as c2
			on c2.ConferenceID = r.ConferenceID
		where c2.ConferenceID != c1.ConferenceID
	)
	begin
		THROW 50001 , 'Cannot book conference days from different conferences in one order! ' , 1	
		ROLLBACK TRANSACTION
	end
end
GO
--nienachodzenie czasu warsztatów

create trigger [dbo].[overlapping_workshop_time]
on [dbo].[WorkshopParticipants]
after insert
as
begin
	if exists
	( 
		select *
		from Inserted as i
			join WorkshopBooking as wb1 on wb1.WorkshopBookingID = i.WorkshopBookingID
			join Workshops as w1 on w1.WorkshopID = wb1.WorkshopID
		where i.ParticipantID in 
		(select wp.ParticipantID 
		 from WorkshopParticipants as wp
			join WorkshopBooking as wb on wb.WorkshopBookingID = wp.WorkshopBookingID
			join Workshops as w on w.WorkshopID = wb.WorkshopID
		where wp.ParticipantID = i.ParticipantID and  w.StartTime < w1.EndTime and w1.StartTime < w.EndTime AND w1.WorkshopID <> wb.WorkshopID)
	)
	begin
		THROW 50001 , 'Workshops cannor overlap each other' , 1	
		ROLLBACK TRANSACTION
	end
end
go
--opadające zniżki 

create trigger monotonous_threshold_of_prices
on Price
after insert, update
as
begin
	Declare @PreviousPriceDiscount numeric(3,2)
	set @PreviousPriceDiscount = isNull((select top 1 Discount from Price as p
								where p.ConferenceID = (select ConferenceID from Inserted)
								and p.UntilDays > (select UntilDays from Inserted)
								order by p.UntilDays asc),1.0)
    Declare @NextPriceDiscount numeric(3,2)
	set @NextPriceDiscount = isNull((select top 1 Discount from Price as p 
							 where p.ConferenceID = (select ConferenceID from Inserted)
							 and p.UntilDays < (select UntilDays from Inserted)
							 order by p.UntilDays desc),0.0)
	if @PreviousPriceDiscount < (select Discount from Inserted) or @NextPriceDiscount > (select Discount from Inserted)
	begin
		THROW 50001 , 'Prices are not in correct order' ,1
		ROLLBACK TRANSACTION
	end
END
GO
--propagacja anulacji zamówienia	
	
CREATE TRIGGER [dbo].[order_canceled_trigger]
	ON [dbo].[Reservation]
	AFTER UPDATE
AS
	BEGIN

		UPDATE wb
		SET wb.isCancelled = i.isCancelled
		FROM WorkshopBooking wb
			JOIN ConferenceDayBooking cdb ON wb.ConferenceDayBookingID=cdb.ConferenceDayBookingID
			JOIN ConferenceDay as cd ON cd.ConferenceDayID = cdb.ConferenceDayID
			JOIN Conferences as c ON c.ConferenceID = cd.ConferenceID
			JOIN Inserted i ON c.ConferenceID = i.ConferenceID
 
		UPDATE cdb
		SET cdb.isCancelled = i.isCancelled
		FROM ConferenceDayBooking cdb
			JOIN ConferenceDay as cd ON cd.ConferenceDayID = cdb.ConferenceDayID
			JOIN Conferences as c ON c.ConferenceID = cd.ConferenceID
			JOIN Inserted i ON c.ConferenceID = i.ConferenceID
	END
GO
--sprawdzenie, czy wystarczylo miejsc w konf
CREATE TRIGGER [dbo].[too_few_conference_day_register]
ON [dbo].[ConferenceDayBooking]
	AFTER INSERT
AS
	BEGIN
		IF EXISTS
		(
		SELECT * FROM inserted AS i
		WHERE dbo.funcConferenceDayFreePlaces(i.ConferenceDayID)<0
		)
	BEGIN
		THROW 50001, 'Too few free places to register this many conference day attendees.', 1
	END
END
GO
--sprawdzenie, czy wystarczylo miejsc w warsztacie

CREATE TRIGGER [dbo].[too_few_workshop_places_trigger]
ON [dbo].[WorkshopBooking]
	AFTER INSERT
AS
	BEGIN
		IF EXISTS
		(
			SELECT * FROM inserted AS i
			WHERE dbo.funcWorkshopFreePlaces(i.WorkshopID) < 0
		)
		BEGIN
			THROW 50001, 'Too few free places to register this many workshop attendees.',1
		END
	END
GO	


--Sprawdzenie limitu przypisania uczestników do rezerwacji
	
CREATE 	TRIGGER [dbo].[attendees_not_above_reservation_trigger]
ON [dbo].[Participants]
	AFTER INSERT
AS
	BEGIN
		IF EXISTS
		(
			SELECT *
			FROM inserted AS i
			GROUP BY i.ConferenceDayBookingID
			HAVING EXISTS(
				SELECT *
				FROM ConferenceDayBooking cdb
				WHERE cdb.ConferenceDayBookingID=i.ConferenceDayBookingID
					AND (cdb.NormalTickets + cdb.ConcessionaryTickets) < 	(SELECT COUNT(*)
																			FROM Participants as p
																			WHERE p.ConferenceDayBookingID=cdb.ConferenceDayBookingID
																			GROUP BY p.ConferenceDayBookingID)
			)
	
		)
		BEGIN
			THROW 50001, 'Number of attendees must not exceed number of reservations', 1
		END
	END
GO	
	--Sprawdzenie limitu przypisania uczestników do warsztatu
	
CREATE 	TRIGGER [dbo].[attendees_not_above_reservation_trigger_workshops]
ON [dbo].[WorkshopParticipants]
	AFTER INSERT
AS
	BEGIN
		IF EXISTS
		(
			SELECT *
			FROM inserted AS i
			GROUP BY i.WorkshopBookingID
			HAVING EXISTS(
				SELECT *
				FROM WorkshopBooking wb
				WHERE wb.WorkshopBookingID=i.WorkshopBookingID
					AND (wb.NormalTickets + wb.ConcessionaryTickets) <	(SELECT COUNT(*)
												FROM WorkshopParticipants as wp
												WHERE wp.WorkshopBookingID=wb.WorkshopBookingID
												GROUP BY wp.WorkshopBookingID)
			)
	
		)
		BEGIN
			THROW 50001, 'Number of attendees must not exceed number of reservations', 1
		END
	END
go

-- opłacenie po anulacji
CREATE TRIGGER [dbo].[check_payments_opportunity]
ON [dbo].[Reservation]
	AFTER INSERT, UPDATE
AS
	BEGIN
	IF EXISTS 
	(
		SELECT * FROM inserted AS i
		WHERE (isCancelled = 1)
	)
	BEGIN
		THROW 50001, 'Payment cannot be added',1
	END
END
GO
--zamówienie po dniu konferencji
CREATE TRIGGER [dbo].[order_before_conference_day_trigger]
	ON [dbo].[Reservation]
	AFTER INSERT, UPDATE
AS
	BEGIN 
		IF EXISTS(
		SELECT * 
		FROM inserted AS i
			JOIN Conferences as c
			ON c.ConferenceID = i.ConferenceID
			WHERE c.EndDate<=i.ReservationDate
		)
	BEGIN
		THROW 50001, 'Order cannot be placed for conference day in the past', 1
	END
END
GO
