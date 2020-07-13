if exists (select * from sys.databases where name = 'ConferencesBlecharczykJablecki')
drop database ConferencesBlecharczykJablecki

create database ConferencesBlecharczykJablecki

if OBJECT_ID('Client','U') is not null
	drop table Client
	
CREATE TABLE Client (
    ClientID int  NOT NULL IDENTITY,
    ContactName varchar(20)  NOT NULL,
    CONSTRAINT Client_unique UNIQUE (ContactName),
    CONSTRAINT Client_pk PRIMARY KEY  (ClientID)
);

if OBJECT_ID('Company','U') is not null
	drop table Company
CREATE TABLE Company (
    CompanyID int  NOT NULL IDENTITY,
    ClientID int  NOT NULL,
    City varchar(30)  NOT NULL,
    Street varchar(30)  NOT NULL,
    HomePage varchar(30)  NULL,
    Country varchar(30)  NOT NULL,
    Email varchar(30)  NOT NULL CHECK (Email like '%@%'),
    Phone varchar(9)  NOT NULL CHECK ((LEN(Phone)=9 AND ISNUMERIC(Phone)=1)),
    CompanyName varchar(30)  NOT NULL,
    CONSTRAINT company_uniques UNIQUE (Email, Phone, CompanyName),
    CONSTRAINT Company_pk PRIMARY KEY  (CompanyID)
);

if OBJECT_ID('ConferenceDay','U') is not null
	drop table ConferenceDay
CREATE TABLE ConferenceDay (
    ConferenceDayID int  NOT NULL IDENTITY,
    ConferenceID int  NOT NULL,
    Date date  NOT NULL,
    Limit int  NOT NULL CHECK (Limit >= 0),
    CONSTRAINT ConferenceDay_pk PRIMARY KEY  (ConferenceDayID)
);

CREATE INDEX ConferenceDay_idx on ConferenceDay (Date ASC)
;

if OBJECT_ID('ConferenceDayBooking','U') is not null
	drop table ConferenceDayBooking
CREATE TABLE ConferenceDayBooking (
    ConferenceDayBookingID int  NOT NULL IDENTITY,
    ConferenceDayID int  NOT NULL,
    ReservationID int  NOT NULL,
    NormalTickets int  NOT NULL CHECK (NormalTickets >= 0),
    ConcessionaryTickets int  NOT NULL CHECK (ConcessionaryTickets >= 0),
    isCancelled bit  NOT NULL DEFAULT 0,
    CONSTRAINT ConferenceDayBooking_pk PRIMARY KEY  (ConferenceDayBookingID)
);

if OBJECT_ID('Conferences','U') is not null
	drop table Conferences
CREATE TABLE Conferences (
    ConferenceID int  NOT NULL IDENTITY,
    ConferenceName varchar(50)  NOT NULL,
    BeginDate date  NOT NULL,
    EndDate date  NOT NULL,
    Price money  NOT NULL CHECK (Price >= 0.0),
    StudentDiscount numeric(3,2)  NOT NULL DEFAULT 0 CHECK (StudentDiscount BETWEEN 0 AND 1.0),
    CONSTRAINT validConfDates CHECK (EndDate >= BeginDate),
    CONSTRAINT Conferences_pk PRIMARY KEY  (ConferenceID)
);

CREATE INDEX BeginDate_idx on Conferences (BeginDate ASC)
;

CREATE INDEX EndDate_idx on Conferences (EndDate ASC)
;

if OBJECT_ID('Employees','U') is not null
	drop table Employees
CREATE TABLE Employees (
    CompanyID int  NOT NULL,
    PersonalDataID int  NOT NULL,
    CONSTRAINT PersonalDataID PRIMARY KEY  (CompanyID,PersonalDataID)
);

if OBJECT_ID('IndividualClients','U') is not null
	drop table IndividualClients
CREATE TABLE IndividualClients (
    IndividualClientID int  NOT NULL IDENTITY,
    PersonalDataID int  NOT NULL,
    ClientID int  NOT NULL,
    CONSTRAINT IndividualClients_pk PRIMARY KEY  (IndividualClientID)
);

if OBJECT_ID('Participants','U') is not null
	drop table Participants
CREATE TABLE Participants (
    ParticipantID int  NOT NULL IDENTITY,
    ConferenceDayBookingID int  NOT NULL,
    PersonalDataID int  NOT NULL,
    CONSTRAINT Participants_pk PRIMARY KEY  (ParticipantID)
);

if OBJECT_ID('PersonalData','U') is not null
	drop table PersonalData
CREATE TABLE PersonalData (
    PersonalDataID int  NOT NULL IDENTITY,
    FirstName varchar(30)  NOT NULL,
    LastName varchar(30)  NOT NULL,
    Email varchar(30)  NOT NULL CHECK (Email like '%@%'),
    Phone varchar(9)  NOT NULL CHECK ((LEN(Phone)=9 AND ISNUMERIC(Phone)=1)),
    StudentCard varchar(10)  NULL,
    CONSTRAINT PersonalData_uniques UNIQUE (Email, StudentCard, Phone),
    CONSTRAINT PersonalData_pk PRIMARY KEY  (PersonalDataID)
);

if OBJECT_ID('Price','U') is not null
	drop table Price
CREATE TABLE Price (
    PriceID int  NOT NULL IDENTITY,
    ConferenceID int  NOT NULL,
    Discount numeric(3,2)  NOT NULL DEFAULT 0.0 CHECK (Discount BETWEEN 0 AND 1.0),
    UntilDays int  NOT NULL CHECK (UntilDays >= 0),
    CONSTRAINT Price_pk PRIMARY KEY  (PriceID)
);

CREATE INDEX discount_idx on Price (Discount ASC)
;

CREATE INDEX untildays_idx on Price (UntilDays ASC)
;

if OBJECT_ID('Reservation','U') is not null
	drop table Reservation
CREATE TABLE Reservation (
    ReservationID int  NOT NULL IDENTITY,
    ClientID int  NOT NULL,
    ConferenceID int  NOT NULL,
    ReservationDate date  NOT NULL,
    PaymentDate date  NULL,
    isCancelled bit  NOT NULL DEFAULT 0,
    Value money  NOT NULL,
    CONSTRAINT Reservation_pk PRIMARY KEY  (ReservationID)
);

CREATE INDEX ReservationDate_idx on Reservation (ReservationDate ASC)
;

if OBJECT_ID('WorkshopBooking','U') is not null
	drop table WorkshopBooking
CREATE TABLE WorkshopBooking (
    WorkshopBookingID int  NOT NULL IDENTITY,
    WorkshopID int  NOT NULL,
    ConferenceDayBookingID int  NOT NULL,
    NormalTickets int  NOT NULL CHECK (NormalTickets >= 0),
    ConcessionaryTickets int  NOT NULL CHECK (ConcessionaryTickets >= 0),
    isCancelled bit  NOT NULL DEFAULT 0,
    CONSTRAINT WorkshopBooking_pk PRIMARY KEY  (WorkshopBookingID)
);

if OBJECT_ID('WorkshopParticipants','U') is not null
	drop table WorkshopParticipants
CREATE TABLE WorkshopParticipants (
    ParticipantID int  NOT NULL,
    WorkshopBookingID int  NOT NULL,
    CONSTRAINT WorkshopParticipants_pk PRIMARY KEY  (ParticipantID,WorkshopBookingID)
);
if OBJECT_ID('Workshops','U') is not null
	drop table Workshops
CREATE TABLE Workshops (
    WorkshopID int  NOT NULL IDENTITY,
    ConferenceDayID int  NOT NULL,
    WorkshopName varchar(50)  NOT NULL,
    StartTime time(7)  NOT NULL,
    EndTime time(7)  NOT NULL,
    Price money  NOT NULL CHECK (Price >= 0),
    Limit int  NOT NULL CHECK (Limit >= 0),
    CONSTRAINT ProperTime CHECK (EndTime > StartTime),
    CONSTRAINT Workshops_pk PRIMARY KEY  (WorkshopID)
);

CREATE INDEX StartTime_idx on Workshops (StartTime ASC)
;

CREATE INDEX EndTime_idx on Workshops (EndTime ASC)
;

-- foreign keys
-- Reference: Company_Client (table: Company)
ALTER TABLE Company ADD CONSTRAINT Company_Client
    FOREIGN KEY (ClientID)
    REFERENCES Client (ClientID);

-- Reference: ConferenceDayBooking_ConferenceDay (table: ConferenceDayBooking)
ALTER TABLE ConferenceDayBooking ADD CONSTRAINT ConferenceDayBooking_ConferenceDay
    FOREIGN KEY (ConferenceDayID)
    REFERENCES ConferenceDay (ConferenceDayID);

-- Reference: ConferenceDayBooking_Reservation (table: ConferenceDayBooking)
ALTER TABLE ConferenceDayBooking ADD CONSTRAINT ConferenceDayBooking_Reservation
    FOREIGN KEY (ReservationID)
    REFERENCES Reservation (ReservationID);

-- Reference: ConferenceDay_Conferences (table: ConferenceDay)
ALTER TABLE ConferenceDay ADD CONSTRAINT ConferenceDay_Conferences
    FOREIGN KEY (ConferenceID)
    REFERENCES Conferences (ConferenceID);

-- Reference: Employees_Company (table: Employees)
ALTER TABLE Employees ADD CONSTRAINT Employees_Company
    FOREIGN KEY (CompanyID)
    REFERENCES Company (CompanyID);

-- Reference: Employees_PersonalData (table: Employees)
ALTER TABLE Employees ADD CONSTRAINT Employees_PersonalData
    FOREIGN KEY (PersonalDataID)
    REFERENCES PersonalData (PersonalDataID);

-- Reference: IndividualClients_Client (table: IndividualClients)
ALTER TABLE IndividualClients ADD CONSTRAINT IndividualClients_Client
    FOREIGN KEY (ClientID)
    REFERENCES Client (ClientID);

-- Reference: IndividualClients_PersonalData (table: IndividualClients)
ALTER TABLE IndividualClients ADD CONSTRAINT IndividualClients_PersonalData
    FOREIGN KEY (PersonalDataID)
    REFERENCES PersonalData (PersonalDataID);

-- Reference: Participants_ConferenceDayBooking (table: Participants)
ALTER TABLE Participants ADD CONSTRAINT Participants_ConferenceDayBooking
    FOREIGN KEY (ConferenceDayBookingID)
    REFERENCES ConferenceDayBooking (ConferenceDayBookingID);

-- Reference: Participants_PersonalData (table: Participants)
ALTER TABLE Participants ADD CONSTRAINT Participants_PersonalData
    FOREIGN KEY (PersonalDataID)
    REFERENCES PersonalData (PersonalDataID);

-- Reference: Price_Conferences (table: Price)
ALTER TABLE Price ADD CONSTRAINT Price_Conferences
    FOREIGN KEY (ConferenceID)
    REFERENCES Conferences (ConferenceID);

-- Reference: Reservation_Client (table: Reservation)
ALTER TABLE Reservation ADD CONSTRAINT Reservation_Client
    FOREIGN KEY (ClientID)
    REFERENCES Client (ClientID);

-- Reference: Reservation_Conferences (table: Reservation)
ALTER TABLE Reservation ADD CONSTRAINT Reservation_Conferences
    FOREIGN KEY (ConferenceID)
    REFERENCES Conferences (ConferenceID);

-- Reference: WorkshopBooking_ConferenceDayBooking (table: WorkshopBooking)
ALTER TABLE WorkshopBooking ADD CONSTRAINT WorkshopBooking_ConferenceDayBooking
    FOREIGN KEY (ConferenceDayBookingID)
    REFERENCES ConferenceDayBooking (ConferenceDayBookingID);

-- Reference: WorkshopBooking_Workshops (table: WorkshopBooking)
ALTER TABLE WorkshopBooking ADD CONSTRAINT WorkshopBooking_Workshops
    FOREIGN KEY (WorkshopID)
    REFERENCES Workshops (WorkshopID);

-- Reference: WorkshopParticipants_Participants (table: WorkshopParticipants)
ALTER TABLE WorkshopParticipants ADD CONSTRAINT WorkshopParticipants_Participants
    FOREIGN KEY (ParticipantID)
    REFERENCES Participants (ParticipantID);

-- Reference: WorkshopParticipants_WorkshopBooking (table: WorkshopParticipants)
ALTER TABLE WorkshopParticipants ADD CONSTRAINT WorkshopParticipants_WorkshopBooking
    FOREIGN KEY (WorkshopBookingID)
    REFERENCES WorkshopBooking (WorkshopBookingID);

-- Reference: Workshops_ConferenceDay (table: Workshops)
ALTER TABLE Workshops ADD CONSTRAINT Workshops_ConferenceDay
    FOREIGN KEY (ConferenceDayID)
    REFERENCES ConferenceDay (ConferenceDayID);
go

