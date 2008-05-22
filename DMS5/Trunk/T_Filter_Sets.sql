/****** Object:  Table [dbo].[T_Filter_Sets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Filter_Sets](
	[Filter_Set_ID] [int] IDENTITY(100,1) NOT NULL,
	[Filter_Type_ID] [int] NOT NULL,
	[Filter_Set_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Filter_Set_Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Date_Created] [datetime] NOT NULL CONSTRAINT [DF_T_Filter_Sets_Date_Created]  DEFAULT (getdate()),
	[Date_Modified] [datetime] NOT NULL CONSTRAINT [DF_T_Filter_Sets_Date_Modified]  DEFAULT (getdate()),
 CONSTRAINT [PK_T_Filter_Sets] PRIMARY KEY CLUSTERED 
(
	[Filter_Set_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT INSERT ON [dbo].[T_Filter_Sets] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Filter_Sets] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Filter_Sets] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Filter_Sets]  WITH CHECK ADD  CONSTRAINT [FK_T_Filter_Sets_T_Filter_Set_Types] FOREIGN KEY([Filter_Type_ID])
REFERENCES [T_Filter_Set_Types] ([Filter_Type_ID])
GO
ALTER TABLE [dbo].[T_Filter_Sets] CHECK CONSTRAINT [FK_T_Filter_Sets_T_Filter_Set_Types]
GO
