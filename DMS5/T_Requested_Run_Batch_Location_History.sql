/****** Object:  Table [dbo].[T_Requested_Run_Batch_Location_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_Batch_Location_History](
	[entry_id] [int] IDENTITY(1000,1) NOT NULL,
	[batch_id] [int] NOT NULL,
	[location_id] [int] NOT NULL,
	[first_scan_date] [datetime] NOT NULL,
	[last_scan_date] [datetime] NULL,
 CONSTRAINT [PK_T_Requested_Run_Batch_Location_History] PRIMARY KEY CLUSTERED 
(
	[entry_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Requested_Run_Batch_Location_History_Batch_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Batch_Location_History_Batch_ID] ON [dbo].[T_Requested_Run_Batch_Location_History]
(
	[batch_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batch_Location_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batch_Location_History_T_Material_Locations] FOREIGN KEY([location_id])
REFERENCES [dbo].[T_Material_Locations] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Batch_Location_History] CHECK CONSTRAINT [FK_T_Requested_Run_Batch_Location_History_T_Material_Locations]
GO
