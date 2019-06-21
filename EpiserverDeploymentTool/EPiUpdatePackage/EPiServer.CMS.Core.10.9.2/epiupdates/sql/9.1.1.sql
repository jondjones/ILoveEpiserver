--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7026)
				select 0, 'Already correct database version'
            else if (@ver = 7025)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[tblContentSoftlink]...';

GO
ALTER TABLE [dbo].[tblContentSoftlink] ALTER COLUMN [LinkURL] NVARCHAR (2048) NOT NULL;

GO
PRINT N'Altering [dbo].[netSoftLinkInsert]...';

GO
ALTER PROCEDURE dbo.netSoftLinkInsert
(
	@OwnerContentID	INT,
	@ReferencedContentGUID uniqueidentifier,
	@LinkURL	NVARCHAR(2048),
	@LinkType	INT,
	@LinkProtocol	NVARCHAR(10),
	@ContentLink	NVARCHAR(255),
	@LastCheckedDate datetime,
	@FirstDateBroken datetime,
	@HttpStatusCode int,
	@LinkStatus int,
	@OwnerLanguageID int,
	@ReferencedLanguageID int
)
AS
BEGIN
	INSERT INTO tblContentSoftlink
		(fkOwnerContentID,
		fkReferencedContentGUID,
	    OwnerLanguageID,
		ReferencedLanguageID,
		LinkURL,
		LinkType,
		LinkProtocol,
		ContentLink,
		LastCheckedDate,
		FirstDateBroken,
		HttpStatusCode,
		LinkStatus)
	VALUES
		(@OwnerContentID,
		@ReferencedContentGUID,
		@OwnerLanguageID,
		@ReferencedLanguageID,
		@LinkURL,
		@LinkType,
		@LinkProtocol,
		@ContentLink,
		@LastCheckedDate,
		@FirstDateBroken,
		@HttpStatusCode,
		@LinkStatus)
END

GO
PRINT N'Altering [dbo].[netSoftLinkByUrl]...';

GO
ALTER PROCEDURE dbo.netSoftLinkByUrl
(
	@LinkURL NVARCHAR(2048),
	@ExactMatch INT = 1
)
AS
BEGIN
	SET NOCOUNT ON
	SELECT 
		pkID,
		fkOwnerContentID AS OwnerContentID,
		fkReferencedContentGUID AS ReferencedContentGUID,
		OwnerLanguageID,
		ReferencedLanguageID,
		LinkURL,
		LinkType,
		LinkProtocol,
		LastCheckedDate,
		FirstDateBroken,
		HttpStatusCode,
		LinkStatus
	FROM tblContentSoftlink 
	WHERE (@ExactMatch=1 AND LinkURL LIKE @LinkURL) OR (@ExactMatch=0 AND LinkURL LIKE (@LinkURL + '%'))
END

GO
PRINT N'Update complete.';

GO
PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7026

GO
PRINT N'Update complete.';
GO