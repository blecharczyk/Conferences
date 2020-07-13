EXEC procAddConference 'Jak projektowac bazy danych','1/10/2019','1/11/2019',200,0.2,300,0.3,20
EXEC procAddConference 'Jak zdac bazy danych','3/10/2018','3/11/2018',200,0.4,350,0.2,25
EXEC procAddConference 'Jak pisac ladny kod?','4/8/2018','4/9/2018',300,0.2,300,0.3,21

--SELECT * FROM ConferenceDay
--select * from Conferences

EXEC procAddWorkshop 1,'Jak zaprojektowac baze danych?','7:00','14:00',150,100
EXEC procAddWorkshop 2,'Jak zaprojektowac dobry diagram?','7:00','8:00',150,100
EXEC procAddWorkshop 3,'Jak zaprojektowac system?','7:00','11:00',150,100
EXEC procAddWorkshop 4,'Jak zaprojektowac symulacje?','9:00','12:00',150,100
EXEC procAddWorkshop 5,'Jak stworzyc sieci neuronowe?','7:00','8:00',150,100
EXEC procAddWorkshop 6,'Jak zdobyc doświadczenie w pracy zespołowej?','8:00','11:00',150,100

--SELECT * FROM Workshops

EXEC procAddIndividualClient 'AZX','Chris','Hemswroth', 'avenger@gmail.com', '123432567'
EXEC procAddIndividualClient 'AZY','Linus','Torvalds', 'linux@lin.com', '123432561'
EXEC procAddIndividualClient 'AZZ','Bill','Gates', 'winr@win.com', '323432567'

--SELECT * FROM Client
--SELECT * FROM IndividualClients
--SELECT * FROM PersonalData
--select * from Company

exec procAddCompanyClient 'Microsoft', 'Waszyngton', 'Parkowa', 'microsoftpl', 'USA', 'microsoft@microsoft', '333555777', 'Microfoft Corporation'
exec procAddCompanyClient 'Tesla', 'Krakow', 'Szewska', 'teslapl', 'Polska', 'musk@mail', '222444666', 'Tesla Motors'

EXEC procAddReservationIndividual 1, 1, '1/1/2019', '1/1/2019', 0, 290
EXEC procAddReservationIndividual 2, 1, '1/1/2019', '1/1/2019', 0, 290
EXEC procAddReservationIndividual 3, 1, '1/1/2019', '1/1/2019', 0, 290

EXEC procAddReservationCompany 5, 3, '4/2/2018','4/2/2018',0,3270
EXEC procAddReservationCompany 4, 2, '3/8/2018','3/9/2018',0,4340

--SELECT * FROM reservation

EXEC procAddConferenceDayBookingIndividual 1,1
EXEC procAddConferenceDayBookingIndividual 2,2
EXEC procAddConferenceDayBookingIndividual 2,3

EXEC procAddConferenceDayBookingCompany 3,5,1,0
EXEC procAddConferenceDayBookingCompany 6,4,0,1



--SELECT * FROM ConferenceDayBooking

EXEC procAddConferenceIndividualParticipant 1,'Chris','Hemswroth', 'avenger@gmail.com', '123432567'
EXEC procAddConferenceIndividualParticipant 2,'Linus','Torvalds', 'linux@lin.com', '123432561'
EXEC procAddConferenceIndividualParticipant 3,'Bill','Gates', 'winr@win.com', '323432567'

EXEC procAddConferenceCompanyParticipant 5, 'Asterix', 'Galfonix', 'galia@gmail.com', '533234098', 2, 'SDEFR12345'
EXEC procAddConferenceCompanyParticipant 4, 'Kubus', 'Puchatek', 'miodek@gmail.com', '533234008', 1
EXEC procAddWorkshopBookingIndividual 1, 1
EXEC proccAddWorkshopIndividualParticipant 1,1

EXEC procAddWorkshopBookingCompany 6, 5, 1, 0
EXEC procAddWorkshopCompanyParticipant 4, 2

--SELECT * FROM Participants
--SELECT * FROM WorkshopParticipants
--SELECT * FROM WorkshopBooking