/****** Object:  Table [dbo].[T_Data_Folder_Create_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Folder_Create_Queue](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[State] [int] NOT NULL,
	[Source_DB] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Source_Table] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Source_ID] [int] NULL,
	[Source_ID_Field_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Path_Local_Root] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Path_Shared_Root] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Path_Folder] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Command] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NULL,
 CONSTRAINT [PK_Data_Folder_Create_Queue] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Folder_Create_Queue] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Folder_Create_Queue] ADD  CONSTRAINT [DF_T_Data_Folder_Create_Queue_State_ID]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[T_Data_Folder_Create_Queue] ADD  CONSTRAINT [DF_Data_Folder_Create_Queue_Command]  DEFAULT ('add') FOR [Command]
GO
ALTER TABLE [dbo].[T_Data_Folder_Create_Queue] ADD  CONSTRAINT [DF_T_Data_Folder_Create_Queue_Created]  DEFAULT (getdate()) FOR [Created]
GO
