--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7024)
				select 0, 'Already correct database version'
            else if (@ver = 7023)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery

GO
PRINT N'Altering [dbo].[netActivityLogCommentSave]...';


GO
ALTER PROCEDURE [dbo].[netActivityLogCommentSave]
(
	@Id			BIGINT = 0 OUTPUT,
	@EntryId	BIGINT, 
    @Author		NVARCHAR(255) = NULL, 
    @Created	DATETIME, 
    @LastUpdated DATETIME, 
    @Message	NVARCHAR(max)
)
AS            
BEGIN
	IF (@Id = 0)
	BEGIN
		INSERT INTO [tblActivityLogComment] VALUES(@EntryId, @Author, @Created, @Created, @Message)
		SET @Id = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE [tblActivityLogComment] SET
			[EntryId] = @EntryId,
			[Author] = @Author,
			[LastUpdated] = @LastUpdated,
			[Message] = @Message
		WHERE pkID = @Id
	END
END
GO


PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7024
GO

PRINT N'Update complete.';


GO
