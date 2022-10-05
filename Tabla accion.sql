-- Aquí se guardan las acciones que se realizan como "entrada", "salida", "automatico"
create table Acciones_n(
    accion varchar(30) not null primary key,
    tecla varchar(1) not null unique,
    foreign key (tecla) references teclas_n(tecla) on delete cascade
);
