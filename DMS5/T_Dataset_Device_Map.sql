/****** Object:  Table [dbo].[T_Dataset_Device_Map] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Device_Map](
	[Dataset_ID] [int] NOT NULL,
	[Device_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Dataset_Device_Map] PRIMARY KEY CLUSTERED 
(
	[Dataset_ID] ASC,
	[Device_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Dataset_Device_Map]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Device_Map_T_Dataset] FOREIGN KEY([Dataset_ID])
REFERENCES [dbo].[T_Dataset] ([Dataset_ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Dataset_Device_Map] CHECK CONSTRAINT [FK_T_Dataset_Device_Map_T_Dataset]
GO
ALTER TABLE [dbo].[T_Dataset_Device_Map]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Device_Map_T_Dataset_Device] FOREIGN KEY([Device_ID])
REFERENCES [dbo].[T_Dataset_Device] ([Device_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Device_Map] CHECK CONSTRAINT [FK_T_Dataset_Device_Map_T_Dataset_Device]
GO
