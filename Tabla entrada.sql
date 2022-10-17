create table entradas_n(
    id_entrada bigint not null primary key AUTO_INCREMENT,
    fecha date not null default now(),
    hora_entrada time not null default now(),
    hora_salida time,
    no_control varchar(10) not null,
    lugar varchar(40) not null,
    nombre varchar(40),
    foreign key (lugar) references Lugares_n(lugar) on delete cascade
);