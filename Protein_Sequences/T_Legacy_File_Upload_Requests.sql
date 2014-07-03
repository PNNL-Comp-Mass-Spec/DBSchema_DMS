/****** Object:  Table [dbo].[T_Legacy_File_Upload_Requests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Legacy_File_Upload_Requests](
	[Upload_Request_ID] [int] IDENTITY(1,1) NOT NULL,
	[Legacy_File_ID] [int] NOT NULL,
	[Legacy_Filename] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Date_Requested] [datetime] NOT NULL,
	[Date_Uploaded] [datetime] NULL,
	[Upload_Completed] [tinyint] NOT NULL,
	[Authentication_Hash] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Legacy_File_Upload_Requests] PRIMARY KEY CLUSTERED 
(
	[Upload_Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Legacy_File_Upload_Requests] ADD  CONSTRAINT [DF_T_Legacy_File_Upload_Requests_Date_Requested]  DEFAULT (getdate()) FOR [Date_Requested]
GO
ALTER TABLE [dbo].[T_Legacy_File_Upload_Requests] ADD  CONSTRAINT [DF_T_Legacy_File_Upload_Requests_Upload_Completed]  DEFAULT (0) FOR [Upload_Completed]
GO
ALTER TABLE [dbo].[T_Legacy_File_Upload_Requests] ADD  CONSTRAINT [DF_T_Legacy_File_Upload_Requests_Authentication_Hash]  DEFAULT ('') FOR [Authentication_Hash]
GO
