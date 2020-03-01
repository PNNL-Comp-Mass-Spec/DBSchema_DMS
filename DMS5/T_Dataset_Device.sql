/****** Object:  Table [dbo].[T_Dataset_Device] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Device](
	[Device_ID] [int] IDENTITY(100,1) NOT NULL,
	[Device_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Device_Number] [int] NOT NULL,
	[Device_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Device_Model] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Serial_Number] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Software_Version] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Device_Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Dataset_Device] PRIMARY KEY CLUSTERED 
(
	[Device_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Device_Type_Name_Model_Serial_Software] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Dataset_Device_Type_Name_Model_Serial_Software] ON [dbo].[T_Dataset_Device]
(
	[Device_Type] ASC,
	[Device_Name] ASC,
	[Device_Model] ASC,
	[Serial_Number] ASC,
	[Software_Version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Device] ADD  CONSTRAINT [DF_T_Dataset_Device_Device_Number]  DEFAULT ((1)) FOR [Device_Number]
GO
ALTER TABLE [dbo].[T_Dataset_Device] ADD  CONSTRAINT [DF_T_Dataset_Device_Model]  DEFAULT ('') FOR [Device_Model]
GO
ALTER TABLE [dbo].[T_Dataset_Device] ADD  CONSTRAINT [DF_T_Dataset_Device_Serial]  DEFAULT ('') FOR [Serial_Number]
GO
ALTER TABLE [dbo].[T_Dataset_Device] ADD  CONSTRAINT [DF_T_Dataset_Device_Software_Version]  DEFAULT ('') FOR [Software_Version]
GO
ALTER TABLE [dbo].[T_Dataset_Device] ADD  CONSTRAINT [DF_T_Dataset_Device_Device_Description]  DEFAULT ('') FOR [Device_Description]
GO
