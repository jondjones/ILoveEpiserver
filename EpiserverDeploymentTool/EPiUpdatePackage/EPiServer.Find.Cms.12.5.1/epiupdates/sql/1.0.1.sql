--beginvalidatingquery
if exists (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'tblFindDatabaseVersion')
    begin
		select 0, 'Already correct database version'
	end
	else
		select 1, 'Upgrading database'
--endvalidatingquery

GO

CREATE TABLE [dbo].[tblFindDatabaseVersion](
	[Id] int Identity(1,1) PRIMARY KEY,
	[Major] [int] NOT NULL,
	[Minor] [int] NOT NULL,
	[Patch] [int] NOT NULL
) ON [PRIMARY]

GO

CREATE TYPE [dbo].[findIDTable] AS TABLE(
	[ID] [int] NOT NULL
)

GO

insert into tblFindDatabaseVersion(Major, Minor, Patch) values(1,0,1)


GO

PRINT N'Update complete.';