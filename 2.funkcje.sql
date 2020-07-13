

--zwraca wpisy w conferencedays dla podanego id konferencji

CREATE FUNCTION funcConferenceDays
	(
		@ConferenceID INT
	)
	RETURNS @days TABLE
	(
		ConferenceDayID INT,
		Date DATE,
		ParticipantsLimit INT
	)
AS
	BEGIN
		INSERT INTO @days
		SELECT ConferenceDayID, Date, Limit 
		FROM ConferenceDay 
		WHERE ConferenceID=@conferenceID
		RETURN;
	END
go
--Zwraca ilość wolnych miejsc na dany dzień konferencji.
		
CREATE FUNCTION funcConferenceDayFreePlaces
	(
		@ConferenceDayID INT
	)
	RETURNS INT
AS
	BEGIN
		RETURN 
		(
		SELECT cd.Limit - (sum(cdb.NormalTickets + cdb.ConcessionaryTickets))
		FROM ConferenceDay as cd
		LEFT JOIN ConferenceDayBooking as cdb
		ON cd.ConferenceDayID=cdb.ConferenceDayID AND cdb.isCancelled=0
		WHERE cd.ConferenceDayID=@ConferenceDayID
		GROUP BY cdb.ConferenceDayID, cd.Limit
		)
	END
go
--zwraca ilość wolnych miejsc na warsztacie
CREATE FUNCTION funcWorkshopFreePlaces
	(
		@WorkshopID INT
	)
	RETURNS INT
AS
	BEGIN
		RETURN 
		(
		SELECT w.Limit - (sum(wb.ConcessionaryTickets + wb.NormalTickets))
		FROM Workshops as w
		LEFT JOIN WorkshopBooking as wb
		ON w.WorkshopID=wb.WorkshopID AND wb.isCancelled=0
		WHERE w.WorkshopID=@WorkshopID
		GROUP BY w.WorkshopID, w.Limit
		)
	END
	go
--zwraca uczestników konferenci	
CREATE FUNCTION funcConferenceDayParticipants
	(
		@ConferenceID INT
	)
	RETURNS @ParticipantsInfo TABLE
	(
		tConferenceID INT,
		tConferenceDayID INT,
		tParticipantID INT,
		tFirstName VARCHAR(30),
		tLastName VARCHAR(30),
		tEmail VARCHAR(30),
		tPhone VARCHAR(9),
		tStudentCart VARCHAR(10)
	)
AS	
	BEGIN
		INSERT INTO @ParticipantsInfo 
		SELECT c.ConferenceID, cd.ConferenceDayID, p.ParticipantID, pd.FirstName, pd.LastName, pd.Email, pd.Phone, pd.StudentCard
		FROM Conferences AS c
		JOIN ConferenceDay AS cd
		ON c.ConferenceID=cd.ConferenceID
		JOIN ConferenceDayBooking AS cdb
		ON cdb.ConferenceDayID=cd.ConferenceDayID
		JOIN Participants AS p
		ON p.ConferenceDayBookingID=cdb.ConferenceDayBookingID
		JOIN PersonalData AS pd
		ON pd.PersonalDataID=p.PersonalDataID
		WHERE c.ConferenceID=@ConferenceID AND cdb.isCancelled = 0
		RETURN
	END
go
	
--uczestnicy warsztatu
CREATE FUNCTION funcWorkshopParticipants
	(
		@WorkshopID INT
	)
	RETURNS @ParticipantsInfo TABLE
	(
		tWorkshopID INT,
		tConferenceDayID INT,
		tParticipantID INT,
		tFirstName VARCHAR(30),
		tLastName VARCHAR(30),
		tEmail VARCHAR(30),
		tPhone VARCHAR(9),
		tStudentCart VARCHAR(10)
	)
AS	
	BEGIN
		INSERT INTO @ParticipantsInfo 
		SELECT w.WorkshopID, cd.ConferenceDayID, p.ParticipantID, pd.FirstName, pd.LastName, pd.Email, pd.Phone, pd.StudentCard
		FROM Workshops AS w
		JOIN ConferenceDay AS cd
		ON w.ConferenceDayID=cd.ConferenceDayID
		JOIN ConferenceDayBooking AS cdb
		ON cdb.ConferenceDayID=cd.ConferenceDayID
		JOIN Participants AS p
		ON p.ConferenceDayBookingID=cdb.ConferenceDayBookingID
		JOIN PersonalData AS pd
		ON pd.PersonalDataID=p.PersonalDataID
		WHERE w.WorkshopID=@WorkshopID AND cdb.isCancelled = 0
		RETURN
	END	
go	


--aktualna obniżka dotycząca danej rezerwacji
CREATE FUNCTION funcReservationDiscount
	(
		@ReservationID INT
	)
	RETURNS NUMERIC(3,2)
AS
	BEGIN
		RETURN
		(
		SELECT isNull((	select top 1 Discount 
						from Price where UntilDays > DATEDIFF(DAY,r.ReservationDate,c.BeginDate) and PriceID = p.PriceID 
						order by UntilDays asc),0.0)
		FROM Reservation AS r
		JOIN Conferences as c
		ON r.ConferenceID=c.ConferenceID
		JOIN Price as p
		ON p.ConferenceID=c.ConferenceID
		WHERE r.ReservationID=@ReservationID 					
	)
	end
go
--koszt dnia konferencji dla zamówienia 

create function funcTotalCostOfConfday
    (
		@ReservationID int
	)
	returns money
as
begin
	return
	(
		select sum( cdb.NormalTickets * c.Price + cdb.ConcessionaryTickets * c.Price * (1-c.StudentDiscount))
		from ConferenceDayBooking as cdb
			join Reservation as r on r.ReservationID = cdb.ReservationID
			join Conferences as c on c.ConferenceID = r.ConferenceID
		where r.ReservationID = @ReservationID
		group by r.ReservationID
	)
end
go
--koszt warsztatów dla zamówienia
create function funcTotalCostOfWorkshops
	(
		@ReservationID int
	)
	returns money
as
begin
	return
	(
		select isNull(sum(wb.NormalTickets * w.Price + wb.ConcessionaryTickets * w.Price *(1-c.StudentDiscount)),0)
		from Reservation as r
			left join ConferenceDayBooking as cdb on cdb.ReservationID = r.ReservationID
			left join WorkshopBooking as wb on wb.ConferenceDayBookingID = cdb.ConferenceDayBookingID
			left join Workshops as w on w.WorkshopID = wb.WorkshopID 
			join ConferenceDay as cd on cd.ConferenceDayID = w.ConferenceDayID
			join Conferences as c on c.ConferenceID = cd.ConferenceID
		where r.ReservationID = @ReservationID
		group by r.ReservationID

	)
end
go
-- całkowity koszt rezerwacji
create function funcTotalTeservationCost
	(
		@ReservationID int
	)
	returns money
as
begin
	return
	(
		cast((1-dbo.funcReservationDiscount(@ReservationID)) * (dbo.funcTotalCostOfWorkshops(@ReservationID) + dbo.funcTotalCostOfConfday(@ReservationID))  as money)
	)
 
end
go