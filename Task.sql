create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
set nocount on
begin
    /*
        Ошибка 1. В соответствии с правилами
        именования переменных количество строк
        указываем во мн. числе (@RowsCount)
    */
    /*
        Ошибка 6. Все переменные задаются
        в одном объявлении 

        Ошибка 10.
        Избегаем длину поля max
    */
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	declare @ErrorMessage varchar(max)
    /*
        Ошибка 2. Комментарий с таким же отступом как и код, 
        к которому он относится. 
        На уровне с if not exists
    */
-- Проверка на корректность загрузки
	if not exists (
    /*
        Ошибка 3. Содержимое скобок переносится
        на следующую строку 
 
        Ошибка 4. Алиас для таблицы ImportFile
        задается как "imf"
    */
	select 1
	from syn.ImportFile as f
	where f.ID = @ID_Record
		and f.FlagLoaded = cast(1 as bit)
	)
    /*
        Ошибка 5. `begin/end` одном уровне с `if` 
    */
		begin
			set @ErrorMessage = 'Ошибка при загрузке файла, проверьте корректность данных'

			raiserror(@ErrorMessage, 3, 1)
            /*
                Ошибка 16.
                Пустая строка перед return
            */
			return
		end
    /*
        Ошибка 17.
        Нужно проверить на наличие объекта через "if".
        Повторное создание объекта приводит к ошибке
    */
	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
	/*
        Ошибка 7. 
        Между "--"" и комментарием есть один пробел
    */
	--Чтение из слоя временных данных
    /*
        Ошибка 8. 
        Идентификатор "date" - ключевое слово.
        Его необходимо экранировать в []
    */
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	from syn.SA_CustomerSeasonal cs
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
        /*
            Ошибка 9. 
            Сперва указываем поле присоединяемой таблицы:
            cst.Name = cs.CustomerSystemType
        */
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null
    /*
        Ошибка 16.
        Для комментариев в несколько строк используется конструкция /* */
    */
	-- Определяем некорректные записи
	-- Добавляем причину, по которой запись считается некорректной
	select
		cs.*
		,case
            /*
                Ошибка 12. 
                then на 1 отступ от when
            */
			when cc.ID is null then 'UID клиента отсутствует в справочнике "Клиент"'
			when cd.ID is null then 'UID дистрибьютора отсутствует в справочнике "Клиент"'
			when s.ID is null then 'Сезон отсутствует в справочнике "Сезон"'
			when cst.ID is null then 'Тип клиента в справочнике "Тип клиента"'
			when try_cast(cs.DateBegin as date) is null then 'Невозможно определить Дату начала'
			when try_cast(cs.DateEnd as date) is null then 'Невозможно определить Дату начала'
            /*
                Ошибка 13.
                Для повышения читаемости кода длинные условия, формулы, выражения и
                т.п., занимающие более ~75% ширины экрана должны быть разделены на
                несколько строк
            */
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then 'Невозможно определить Активность'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
    /*
        Ошибка 14.
        Все виды join пишутся с 1 отступом
    */
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
    /*
        Ошибка 11. 
        Если есть and , то выравнивать его на 1 табуляцию от join
    */
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	/*
        Удобочитаемость.
        После фильтра WHERE, возможно, нужен
        перенос строчки
    */
    where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
		
end