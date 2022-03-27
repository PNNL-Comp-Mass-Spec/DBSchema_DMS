/****** Object:  Table [dbo].[T_Data_Analysis_Request_Batch_IDs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Analysis_Request_Batch_IDs](
	[Request_ID] [int] NOT NULL,
	[Batch_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Data_Analysis_Request_Request_Batch_ID] PRIMARY KEY CLUSTERED 
(
	[Request_ID] ASC,
	[Batch_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Data_Analysis_Request_Batch_IDs] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Analysis_Request_Batch_IDs] ON [dbo].[T_Data_Analysis_Request_Batch_IDs]
(
	[Batch_ID] ASC,
	[Request_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Batch_IDs]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_Batch_IDs_T_Data_Analysis_Request] FOREIGN KEY([Request_ID])
REFERENCES [dbo].[T_Data_Analysis_Request] ([ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Batch_IDs] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_Batch_IDs_T_Data_Analysis_Request]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Batch_IDs]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Analysis_Request_Batch_IDs_T_Requested_Run_Batches] FOREIGN KEY([Batch_ID])
REFERENCES [dbo].[T_Requested_Run_Batches] ([ID])
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_Batch_IDs] CHECK CONSTRAINT [FK_T_Data_Analysis_Request_Batch_IDs_T_Requested_Run_Batches]
GO
