/****** Object:  Table [dbo].[T_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cell_Culture](
	[CC_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CC_Source_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Owner_PRN] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_PI_PRN] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Type] [int] NULL,
	[CC_Reason] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CC_Campaign_ID] [int] NULL,
	[CC_ID] [int] IDENTITY(200,1) NOT NULL,
	[CC_Created] [datetime] NULL,
 CONSTRAINT [PK_T_Cell_Culture] PRIMARY KEY NONCLUSTERED 
(
	[CC_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Cell_Culture_CC_Name] ******/
CREATE NONCLUSTERED INDEX [IX_T_Cell_Culture_CC_Name] ON [dbo].[T_Cell_Culture] 
(
	[CC_Name] ASC
) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
GRANT DELETE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Source_Name]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Source_Name]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Owner_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Owner_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Type]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Type]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Reason]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Reason]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Campaign_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Campaign_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_ID]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Cell_Culture] ([CC_Created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Cell_Culture] ([CC_Created]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Campaign] FOREIGN KEY([CC_Campaign_ID])
REFERENCES [T_Campaign] ([Campaign_ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Campaign]
GO
ALTER TABLE [dbo].[T_Cell_Culture]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name] FOREIGN KEY([CC_Type])
REFERENCES [T_Cell_Culture_Type_Name] ([ID])
GO
ALTER TABLE [dbo].[T_Cell_Culture] CHECK CONSTRAINT [FK_T_Cell_Culture_T_Cell_Culture_Type_Name]
GO
