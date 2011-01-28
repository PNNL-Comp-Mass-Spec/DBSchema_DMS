/****** Object:  Table [dbo].[T_EMSL_Instrument_Category_Assignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instrument_Category_Assignment](
	[Category_Name] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument_Name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_EMSL_Instrument_Category_Assignment] PRIMARY KEY CLUSTERED 
(
	[Category_Name] ASC,
	[Instrument_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Category_Assignment]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_Instrument_Category_Assignment_T_EMSL_Instrument_Category] FOREIGN KEY([Category_Name])
REFERENCES [T_EMSL_Instrument_Category] ([Category])
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Category_Assignment] CHECK CONSTRAINT [FK_T_EMSL_Instrument_Category_Assignment_T_EMSL_Instrument_Category]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Category_Assignment]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_Instrument_Category_Assignment_T_Instrument_Name] FOREIGN KEY([Instrument_Name])
REFERENCES [T_Instrument_Name] ([IN_name])
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Category_Assignment] CHECK CONSTRAINT [FK_T_EMSL_Instrument_Category_Assignment_T_Instrument_Name]
GO
