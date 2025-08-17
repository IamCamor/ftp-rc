import i18n from 'i18next'; import { initReactI18next } from 'react-i18next'
const res={ru:{translation:{map:'Карта',feed:'Лента',add:'Добавить',catch:'Улов',place:'Место'}},en:{translation:{map:'Map',feed:'Feed',add:'Add',catch:'Catch',place:'Place'}}}
i18n.use(initReactI18next).init({resources:res,lng:'ru',fallbackLng:'en',interpolation:{escapeValue:false}}); export default i18n
