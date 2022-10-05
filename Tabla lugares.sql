create table Lugares_n(
    lugar varchar(40) primary key,
    tecla varchar(1) not null unique,
    foreign key (tecla) references teclas_n(tecla) on delete cascade
);