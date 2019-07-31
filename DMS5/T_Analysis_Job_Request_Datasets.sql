/****** Object:  Table [dbo].[T_Analysis_Job_Request_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Request_Datasets](
	[Request_ID] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
 CONSTRAINT [T_Analysis_Job_Request_Datasets_PK] PRIMARY KEY CLUSTERED 
(
	[Request_ID] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Analysis_Job_Request_Datasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Analysis_Job_Request_Datasets] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Request_Datasets] TO [Limited_Table_Write] AS [dbo]
GO
/****** Object:  Index [IX_T_Analysis_Job_Request_Datasets_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Analysis_Job_Request_Datasets_DatasetID] ON [dbo].[T_Analysis_Job_Request_Datasets]
(
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
