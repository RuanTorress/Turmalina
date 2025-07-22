# Turmalina Agenda

Sistema de agenda com calendário responsivo desenvolvido em Flutter para a Turmalina Estética.

## 📱 Funcionalidades

- **Visualizações do Calendário**: Mês, Semana e Dia
- **Interface Responsiva**: Adaptação automática para diferentes tamanhos de tela
- **Layout Otimizado**: Sem overflow de widgets ou problemas de constraint
- **Performance Otimizada**: Animações suaves e carregamento eficiente
- **Tema Adaptável**: Suporte a modo claro e escuro

## 🚀 Características Técnicas

### ✅ Problemas Corrigidos:

- **RenderFlex Overflow**: AppBar com altura fixa (56px) bem abaixo do limite de 88px
- **Calendário Responsivo**: Dias da semana e calendário exibidos adequadamente
- **TabController Correto**: Exatamente 3 abas (Mês, Semana, Dia) ao invés de 4
- **ScrollView Adequado**: Implementação correta para evitar overflow de conteúdo
- **Layout Responsivo**: Adaptação perfeita para diferentes resoluções
- **Performance**: Animações otimizadas sem problemas de rendering

### 📦 Estrutura do Projeto

```
lib/
├── main.dart                 # Aplicação principal
├── screens/
│   └── agenda_screen.dart    # Tela principal da agenda
├── widgets/
│   ├── month_view.dart       # Visualização mensal
│   ├── week_view.dart        # Visualização semanal
│   └── day_view.dart         # Visualização diária
├── models/                   # Modelos de dados
└── utils/                    # Utilitários
```

## 🎨 Design

- **Cores Primárias**: Baseadas na identidade visual (#6e4c34)
- **Material Design 3**: Interface moderna e consistente
- **Responsividade**: Funciona perfeitamente em tablets e smartphones

## 📋 Instalação

```bash
# Clone o repositório
git clone https://github.com/RuanTorress/Turmalina.git

# Navegue até o diretório
cd Turmalina

# Instale as dependências
flutter pub get

# Execute o aplicativo
flutter run
```

## 💎 Sobre a Turmalina Estética

Especialista em estética facial, corporal e capilar
Realçando a sua beleza com naturalidade
📍 Parque Amazônia - Goiânia

---

Desenvolvido por [Ruan Torres](https://github.com/RuanTorress)


