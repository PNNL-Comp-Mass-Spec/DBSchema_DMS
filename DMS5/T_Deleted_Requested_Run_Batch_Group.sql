/****** Object:  Table [dbo].[T_Deleted_Requested_Run_Batch_Group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Deleted_Requested_Run_Batch_Group](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Batch_Group_ID] [int] NOT NULL,
	[Batch_Group] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner_User_ID] [int] NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Deleted_Requested_Run_Batch_Group] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Deleted_Requested_Run_Batch_Group] TO [Limited_Table_Write] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Deleted_Requested_Run_Batch_Group] ******/
CREATE NONCLUSTERED INDEX [IX_T_Deleted_Requested_Run_Batch_Group] ON [dbo].[T_Deleted_Requested_Run_Batch_Group]
(
	[Batch_Group] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
