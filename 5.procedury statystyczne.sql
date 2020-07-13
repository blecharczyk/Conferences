--PROCEDURY STATYSTYCZNE 

--popularnosc klientów (ilosc rezerwacji)
CREATE PROCEDURE show_clients_popularity
as
BEGIN
	SELECT  Name, COUNT(*) AS Number
	FROM (select PersonalDataID, FirstName + ' ' +LastName as Name from PersonalData) as pd 
	JOIN IndividualClients as ic
	ON pd.PersonalDataID=ic.PersonalDataID
	JOIN Client as c
	ON ic.ClientID=c.ClientID
	JOIN Reservation as r
	ON r.ClientID = c.ClientID
	GROUP BY Name
	
	UNION
	
	SELECT co.CompanyName as Name, COUNT(*) AS Number 
	FROM Company as co
	JOIN Client as cl
	ON co.ClientID=cl.ClientID
	JOIN Reservation as r
	ON r.ClientID=cl.ClientID
	GROUP BY co.CompanyName
END
go
--lista uczestników dni konferencji dla wybranej konferencji
create PROCEDURE proc_showConferenceDaysParticipants
	@confID int
as
begin
	select c.ConferenceName, cd.Date, pd.FirstName,  pd.LastName 
	from Conferences as c
		join ConferenceDay as cd 
		on cd.ConferenceID = c.ConferenceID
		join ConferenceDayBooking as cdb
		on cdb.ConferenceDayID = cd.ConferenceDayID
		join Participants as p
		on p.ConferenceDayBookingID = cdb.ConferenceDayBookingID
		join PersonalData as pd
		on pd.PersonalDataID = p.PersonalDataID
	where c.ConferenceID = @confID
	group by ConferenceName, cd.Date,  pd.FirstName,  pd.LastName 
	order by 1,2,4
end
go
-- lista uczestników dla danego warsztaty w obrębie konferencji
create PROCEDURE proc_ShowWorkshopParticipants
	@confID int
as
begin 
	select ConferenceName, WorkshopName, pd.FirstName, pd.LastName
	from Conferences as c
		join ConferenceDay as cd 
		on cd.ConferenceID = c.ConferenceID
		join Workshops as w
		on w.ConferenceDayID = cd.ConferenceDayID
		join WorkshopBooking as wb
		on wb.WorkshopID = w.WorkshopID
		join WorkshopParticipants as wp
		on wp.WorkshopBookingID = wb.WorkshopBookingID
		join Participants as p
		on p.ParticipantID = wp.ParticipantID
		join PersonalData as pd
		on pd.PersonalDataID = p.PersonalDataID	
	where c.ConferenceID = @confID		
	group by ConferenceName, WorkshopName, pd.FirstName, pd.LastName
end
go
-- lista wydarzen w obrębie konferencji

create procedure proc_Events
	@ConferenceID INT
AS
BEGIN
	set nocount on 
	BEGIN TRY
	if NOT EXISTS (select * from Conferences where ConferenceID = @ConferenceID)
	BEGIN
		THROW 52000, 'Conference does not exists ', 1
	END
	select c.ConferenceName, cd.ConferenceDayID, (DATEDIFF(dd, c.BeginDate, cd.Date) + 1) as ConferenceDayNo, isNull(w.WorkshopName, 'no workshop') as WorkshopName
	from Conferences as c
		join ConferenceDay as cd
		on c.ConferenceID = cd.ConferenceID
		left join Workshops as w
		on w.ConferenceDayID = cd.ConferenceDayID
	where c.ConferenceID = @ConferenceID
	group by c.ConferenceName, cd.ConferenceDayID, DATEDIFF(dd, c.BeginDate, cd.Date), w.WorkshopName
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot add Conference day booking . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH
END
go

--uczestnicy danego warsztatu	
create procedure workshop_participants
 @WID int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from Workshops where WorkshopID = @WID)
	begin
		THROW 52000, 'Workshop does not exists ', 1
	end
	select wp.ParticipantID, pd.FirstName, pd.LastName, pd.Phone
	from Workshops as w
	left join WorkshopBooking as wb
	on wb.workshopID=w.workshopID
	left join WorkshopParticipants as wp
	on wp.WorkshopBookingID=wb.WorkshopBookingID
	left join Participants as p
	on p.ParticipantID=wp.ParticipantID
	left join personaldata as pd
	on pd.PersonalDataID = p.PersonalDataID
	where w.WorkshopID = @WID 
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participants . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go
--uczestnicy danej konferencji
create procedure conference_participants
 @CID int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from Conferences where ConferenceID = @CID)
	begin
		THROW 52000, 'Conference does not exists ', 1
	end
	select p.ParticipantID, pd.FirstName, pd.LastName, pd.Phone
	from Conferences as c
	join ConferenceDay as cd
	on cd.ConferenceID=c.ConferenceID
	join ConferenceDayBooking as cdb
	on cdb.ConferenceDayID=cd.ConferenceDayID
	join Participants as p
	on p.ConferenceDayBookingID = cdb.ConferenceDayBookingID
	join personaldata as pd
	on pd.PersonalDataID = p.PersonalDataID
	where c.ConferenceID = @CID 
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participants . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go
--uczestnicy danego dnia konferencji
create procedure conferenceday_participants
 @CDID int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from ConferenceDay where ConferenceDayID = @CDID)
	begin
		THROW 52000, 'ConferenceDay does not exists ', 1
	end
	select p.ParticipantID, pd.FirstName, pd.LastName, pd.Phone
	from ConferenceDay as cd
	join ConferenceDayBooking as cdb
	on cdb.ConferenceDayID=cd.ConferenceDayID
	join Participants as p
	on p.ConferenceDayBookingID = cdb.ConferenceDayBookingID
	join personaldata as pd
	on pd.PersonalDataID = p.PersonalDataID
	where cd.ConferenceDayID = @CDID 
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participants . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
-- konferencje danego uczestnika
create procedure participant_conferences
 @PID int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from Participants where ParticipantID = @PID)
	begin
		THROW 52000, 'CParticipant does not exists ', 1
	end
	select c.ConferenceID, c.ConferenceName
	from Participants as p
		join ConferenceDayBooking as cdb on cdb.ConferenceDayBookingID = p.ConferenceDayBookingID
		join ConferenceDay as cd on cdb.ConferenceDayID = cd.ConferenceDayID
		join Conferences as c on c.ConferenceID = cd.ConferenceID
	where p.ParticipantID = @PID
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participant . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go

-- wpływy z rezerwacji dla wybranej konfernecji
create procedure conference_incomes
 @CID int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from Conferences where ConferenceID = @CID)
	begin
		THROW 52000, 'Conference does not exists ', 1
	end
	select r.ReservationID, sum(r.Value) as Sum
	from Reservation as r
	where r.ConferenceID = @CID and r.isCancelled = 0
	group by r.ReservationID
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find conference . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go

-- nadchodzące konferencje w przeciągu x dni
create procedure comming_conferences
 @days int
as 
BEGIN
	BEGIN TRY
	set nocount on
	if (@days<0)
	begin
		THROW 52000, 'a negative number ', 1
	end
	select c.ConferenceID, c.ConferenceName
	from Conferences as c
	where c.Begindate >= getdate() and c.begindate<=dateadd(day,@days,getdate())
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participant . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go


--procedura-widok sprawdzenie na co jest się zapisanym

create procedure enrollments
	@id int
as
BEGIN
	BEGIN TRY
	set nocount on
	if not exists (select * from Participants where ParticipantID = @id)
	BEGIN
		THROW 52000, 'Participant does not exists ', 1
	END
	select w.WorkshopID, w.StartTime, w.EndTime, cd.ConferenceDayID, cd.Date
	from Participants as p
		 join ConferenceDayBooking as cdb on cdb.ConferenceDayBookingID = p.ConferenceDayBookingID
		 join WorkshopBooking as wb on wb.ConferenceDayBookingID = cdb.ConferenceDayBookingID
		 join ConferenceDay as cd on cd.ConferenceDayID = cdb.ConferenceDayID
		 join Workshops as w on w.WorkshopID = wb.WorkshopID
	where p.ParticipantID = @id and wb.isCancelled = 0 and cdb.isCancelled = 0
	
	END TRY
	BEGIN CATCH
	DECLARE @errorMsg nvarchar (2048)
			= 'Cannot find participant . Error message : '
				+ ERROR_MESSAGE () ;
		; THROW 52000 , @errorMsg ,1
	END CATCH	
END
go

