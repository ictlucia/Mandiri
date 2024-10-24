USE [NTCSSTGDB]
GO
/****** Object:  Table [dbo].[NTCS_MONITOR_REQUEST]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NTCS_MONITOR_REQUEST](
	[Request_Id] [uniqueidentifier] NOT NULL,
	[Service_Name] [varchar](50) NOT NULL,
	[Request_Type] [char](3) NULL,
	[Request_Header] [varchar](max) NULL,
	[Request_Body] [varchar](max) NULL,
	[Create_By] [varchar](50) NULL,
	[Create_Time] [datetime] NULL,
	[Update_time] [datetime] NULL,
	[Status] [char](3) NULL,
	[Tracking_Id] [varchar](50) NULL,
 CONSTRAINT [PK_NTCS_Monitor_Request] PRIMARY KEY CLUSTERED 
(
	[Request_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NTCS_MONITOR_RESPONSE]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NTCS_MONITOR_RESPONSE](
	[Response_Id] [uniqueidentifier] NOT NULL,
	[Response_Message] [varchar](max) NULL,
	[Response_Body] [varchar](max) NULL,
	[Request_Id] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFAPIStatus]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFAPIStatus](
	[ID_Response] [varchar](50) NULL,
	[Status] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RFAPIType]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RFAPIType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Service_Name] [varchar](50) NULL,
	[Type] [char](3) NULL,
 CONSTRAINT [PK_RFAPIService] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetDataLogging]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Titoyan Dwihandoko>
-- Create date: <17 Oktober 2022>
-- Description:	<to get data Logging from API and prime will convert it as CSV file>
-- =============================================
CREATE PROCEDURE [dbo].[SP_GetDataLogging]
	@service varchar(50),
	@from date,
	@to date
AS
BEGIN
	select * from NTCS_MONITOR_REQUEST a
	left join NTCS_MONITOR_RESPONSE b on a.Request_Id = b.Request_Id
	where Service_Name = @service and  Create_Time between @from and @to
END
GO
/****** Object:  StoredProcedure [dbo].[SP_NTCS_Monitor]    Script Date: 10/20/2022 11:30:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Titoyan Dwihandok>
-- Create date: <10 Oktober 2022>
-- Description:	<API Request and Response Logger>
-- =============================================
CREATE PROCEDURE [dbo].[SP_NTCS_Monitor]
	@ServiceName varchar(150),
	@Body varchar(max),
	@Header varchar(max),
	@TrackingID varchar(50)= NULL,
	@RequestID varchar(150) = NULL,
	@ResponseCode varchar(10) = NULL,
	@ResponseMsg varchar(500) = NULL
	
AS
BEGIN
	DECLARE @ID varchar(50),
			@Type varchar(10),
			@Status varchar(3)
	IF @RequestID IS NULL
	BEGIN
		print '1'
		SELECT @Type = [Type] FROM [dbo].[RFAPIType] WHERE [Service_Name] = @ServiceName
		SET @ID = NEWID()
		INSERT INTO [dbo].[NTCS_MONITOR_REQUEST]
			   ([Request_Id]
			   ,[Service_Name]
			   ,[Request_Type]
			   ,[Request_Header]
			   ,[Request_Body]
			   ,[Create_By]
			   ,[Create_Time]
			   ,[Update_time]
			   ,[Status]
			   ,[Tracking_Id])
		 VALUES
			   (@ID
			   ,@ServiceName
			   ,@Type
			   ,@Header
			   ,@Body
			   ,'System'
			   ,GETDATE()
			   ,NULL
			   ,'S'
			   ,@TrackingID
			   )
			   print '3'
		SELECT @ID
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT 1 FROM [dbo].[NTCS_MONITOR_REQUEST] WHERE Request_Id = @RequestID)
		BEGIN
			INSERT INTO [dbo].[NTCS_MONITOR_RESPONSE]
           ([Response_Id]
           ,[Response_Message]
           ,[Response_Body]
           ,[Request_Id])
		 VALUES
			   (NEWID()
			   ,@ResponseMsg
			   ,@Body
			   ,@RequestID
			   )

		SELECT @Status = [Status] FROM [dbo].[RFAPIStatus] WHERE ID_Response = @ResponseCode

		UPDATE NTCS_MONITOR_REQUEST SET Status = @Status, Update_time = GETDATE() where Request_Id = @RequestID

		END
	END
END
GO
