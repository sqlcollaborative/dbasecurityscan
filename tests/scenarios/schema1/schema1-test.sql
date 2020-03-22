use master
go

drop database schema1;
go

create database schema1
go

use schema1;
go

create user schemaOwner without login;
go

create schema unowned;
go

create schema owned  AUTHORIZATION schemaowner;
go

create procedure unowned.sp_test as 
select * from sys.all_columns
GO

create procedure owned.sp_test AS
select * from sys.all_columns
go

create user test without login;
go
grant select on SCHEMA::unowned to test;
go