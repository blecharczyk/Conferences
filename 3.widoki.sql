--Widoki

--płatności klientów
create view  clients_payments_view
as 
	select NameSurname as ClientName, isCancelled, Value
	from ( select PersonalDataID, FirstName + ' ' + LastName as NameSurname from PersonalData) as pd
		join IndividualClients as ic
		on pd.PersonalDataID = ic.PersonalDataID
		join Client as c
		on c.ClientID = ic.ClientID
		join Reservation as r
		on r.ClientID = c.ClientID
	group by NameSurname, isCancelled, Value
	
	union 
	
	select CompanyName as ClientName, isCancelled, Value
	from Company
		join Client as c
		on c.ClientID = Company.ClientID
		join Reservation as r
		on r.ClientID = c.ClientID
	group by CompanyName, isCancelled, Value
go

--przychody 
create view income
AS
	SELECT year(r.PaymentDate) as year, month(r.PaymentDate) as month, sum(r.value) as income
	FROM Reservation as r
	WHERE r.Paymentdate is not null and r.isCancelled = 0
	GROUP BY year(r.PaymentDate), month(r.PaymentDate)
	WITH ROLLUP
go
--ID klientów z ilością ich rezerwacji
create view client_popularity
as
	SELECT c.ClientID, count(*) as liczba
	from Client as C
	join Reservation as r
	on r.clientID=c.clientID and r.isCancelled = 0
	group by c.clientID
go
--nieopłacone rezerwacje (jeszcze nie anulowane)	
create view unpaid_reservations
as
	select reservationID, clientID 
	from reservation
	where paymentdate is  null and isCancelled = 0
go
--lista firm, które nie wprowadziły żadnych danych swoich klientów	
create view no_participants_data_view
as
	select r.clientID, r.reservationID, r.conferenceID
	from Reservation as r
	join ConferenceDayBooking as cdb
	on cdb.ReservationID=r.ReservationID
	join Participants as p
	on p.ConferenceDayBookingID=cdb.ConferenceDayBookingID
	group by cdb.ConferenceDayBookingid, r.clientID, r.reservationID, r.conferenceID
	having count(ParticipantID) = 0
go
--rezerwacje, które muszą być opłacone do jutra, bo zostaną anulowane	
create view by_tomorrow_should_be_paid_view
as
	select ReservationID, ClientID
	from Reservation
	where isCancelled = 0 and paymentdate is null and datediff(day, ReservationDate, getdate()) = 6
go
--widok konferencji z liczbą wolnych i zarezerwowanych miejsc na dany dzień

create view conf_day_free_reserved_seats_view
as
	select cd.ConferenceDayID, cd.Date, isNull([dbo].[funcConferenceDayFreePlaces] ( cd.ConferenceDayID),cd.Limit) as free , cd.Limit
	from ConferenceDay as cd
go


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--widok przedstawiający warsztaty wraz z wolnymi i zarezerwowanymi miejscami
create view workshop_free_reserved_seats_view
as
	select w.WorkshopID, isNull(dbo.funcWorkshopFreePlaces(w.WorkshopID),w.Limit) as free , w.Limit
	from Workshops as w
go

--widok przedstawiający listę konferencji wraz z ich datami rozpoczęcia i zakończenia 

create view conferences_list_view
as
	select c.ConferenceID, c.ConferenceName, c.BeginDate, c.EndDate
	from Conferences as c
go
--widok przedstawiający nachodzące konferencje

create view upcoming_conferences_view
as
	select c.ConferenceID, c.ConferenceName, c.BeginDate
	from Conferences as c
	where DATEDIFF(day,GETDATE(),c.BeginDate)>0
go
--popularność warsztatów

create view workshops_popularity_view
as
	select w.WorkshopID, count(wb.WorkshopBookingID) as numberOfReservations, w.Limit - isNull(dbo.funcWorkshopFreePlaces(w.WorkshopID),w.Limit) as totalTakenSeats
	from Workshops as w
		left join WorkshopBooking as wb on wb.WorkshopID = w.WorkshopID
	group by w.WorkshopID,w.Limit
go
	
--popularność dni konferencji

create view conference_days_popularity_view
as
	select cd.ConferenceDayID, count(cdb.ConferenceDayBookingID) as numberOfReservations, cd.Limit - isNull(dbo.funcConferenceDayFreePlaces( cd.ConferenceDayID),cd.Limit) as totalTakenSeats
	from ConferenceDay as cd
		left join ConferenceDayBooking as cdb on cdb.ConferenceDayID = cd.ConferenceDayID
	group by cd.ConferenceDayID,cd.Limit
go

	
--uczestnicy firmowi
create view employee_participants
as
	select CompanyName, pd.FirstName, pd.LastName
	from Employees as e
		join PersonalData as pd on pd.PersonalDataID = e.PersonalDataID
		join Participants as p on p.PersonalDataID = pd.PersonalDataID
		join ConferenceDayBooking as cdb on cdb.ConferenceDayBookingID = cdb.ConferenceDayBookingID
		join Company as c on c.CompanyID = e.CompanyID
	WHERE cdb.isCancelled = 0
	group by CompanyName, pd.FirstName, pd.LastName

	
	
	
	
	
	
	
	
	
	
	



