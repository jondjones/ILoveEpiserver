--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            declare @ver int
            exec @ver=sp_DatabaseVersion
            if (@ver >= 7012)
				select 0, 'Already correct database version'
            else if (@ver = 7011)
                 select 1, 'Upgrading database'
            else
                 select -1, 'Invalid database version detected'
    end
    else
            select -1, 'Not an EPiServer database'
--endvalidatingquery


GO
PRINT N'Altering [dbo].[tblProject]...';


GO
ALTER TABLE [dbo].[tblProject]
    ADD [DelayPublishUntil] DATETIME NULL;


GO
PRINT N'Altering [dbo].[netProjectGet]...';


GO
ALTER PROCEDURE [dbo].[netProjectGet]
	@ID int
AS
BEGIN
	SELECT pkID, IsPublic, Name, Created, CreatedBy, [Status], DelayPublishUntil, PublishingTrackingToken
	FROM tblProject
	WHERE tblProject.pkID = @ID

	SELECT pkID, Name, Type
	FROM tblProjectMember
	WHERE tblProjectMember.fkProjectID = @ID
	ORDER BY Name ASC
END
GO
PRINT N'Altering [dbo].[netProjectList]...';


GO
ALTER PROCEDURE [dbo].[netProjectList]
	@StartIndex INT = 0,
	@MaxRows INT,
	@Status INT = -1
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @projectIDs TABLE(projectID INT NOT NULL, TotalRows INT NOT NULL);

	WITH PageCTE AS
    (SELECT pkID, [Status],
     ROW_NUMBER() OVER(ORDER BY Name ASC, pkID ASC) AS intRow
     FROM tblProject
	 WHERE @Status  = -1 OR @Status = [Status])

	INSERT INTO  @projectIDs 
		SELECT PageCTE.pkID, (SELECT COUNT(*) FROM PageCTE) AS 'TotalRows' 
		FROM PageCTE 
		WHERE intRow BETWEEN (@StartIndex +1) AND (@MaxRows + @StartIndex)

	--Projects
	SELECT 
		pkID, Name, IsPublic, CreatedBy, Created, [Status], DelayPublishUntil, PublishingTrackingToken
	FROM 
		tblProject 
	INNER JOIN @projectIDs AS projects ON projects.projectID = tblProject.pkID


	--ProjectMembers
	SELECT 
		pkID, projectID, Name, Type
	FROM 
		tblProjectMember 
	INNER JOIN @projectIDs AS projects ON projects.projectID = tblProjectMember.fkProjectID
	ORDER BY projectID, Name

	RETURN COALESCE((SELECT TOP 1 TotalRows FROM @projectIDs), 0)

END
GO
PRINT N'Altering [dbo].[netProjectSave]...';


GO

ALTER PROCEDURE [dbo].[netProjectSave]
	@ID INT,
	@Name	nvarchar(255),
	@IsPublic BIT,
	@Created	datetime,
	@CreatedBy	nvarchar(255),
	@Status INT,
	@DelayPublishUntil datetime = NULL,
	@PublishingTrackingToken nvarchar(255),
	@Members dbo.ProjectMemberTable READONLY
AS
BEGIN
	SET NOCOUNT ON

	IF @ID=0
	BEGIN
		INSERT INTO tblProject(Name, IsPublic, Created, CreatedBy, [Status], DelayPublishUntil, PublishingTrackingToken) VALUES(@Name, @IsPublic, @Created, @CreatedBy, @Status, @DelayPublishUntil, @PublishingTrackingToken)
		SET @ID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		UPDATE tblProject SET Name=@Name, IsPublic=@IsPublic, [Status] = @Status, DelayPublishUntil = @DelayPublishUntil, PublishingTrackingToken = @PublishingTrackingToken  WHERE pkID=@ID
	END

	MERGE tblProjectMember AS Target
    USING @Members AS Source
    ON (Target.pkID = Source.ID AND Target.fkProjectID=@ID)
    WHEN MATCHED THEN 
        UPDATE SET Name = Source.Name, Type = Source.Type
	WHEN NOT MATCHED BY Source AND Target.fkProjectID = @ID THEN
		DELETE
	WHEN NOT MATCHED BY Target THEN
		INSERT (fkProjectID, Name, Type)
		VALUES (@ID, Source.Name, Source.Type);


	SELECT pkID, Name, Type
	FROM tblProjectMember
	WHERE tblProjectMember.fkProjectID = @ID
	ORDER BY Name ASC

	RETURN @ID
END
GO

PRINT N'Altering [dbo].[sp_DatabaseVersion]...';

GO
ALTER PROCEDURE [dbo].[sp_DatabaseVersion]
AS
	RETURN 7012
GO

PRINT N'Update complete.';


GO
