import { BottomNavigation, BottomNavigationAction, Paper } from "@mui/material"
import MapIcon from "@mui/icons-material/Map"
import AddLocationAltIcon from "@mui/icons-material/AddLocationAlt"
import EventIcon from "@mui/icons-material/Event"
import GroupIcon from "@mui/icons-material/Group"
import ChatIcon from "@mui/icons-material/Chat"
import NotificationsIcon from "@mui/icons-material/Notifications"
import { useNavigate, useLocation } from "react-router-dom"

interface Props {
  value?: string
}

export default function BottomNav({ value }: Props) {
  const navigate = useNavigate()
  const location = useLocation()
  const current = value || location.pathname

  return (
    <Paper
      sx={{ position: "fixed", bottom: 0, left: 0, right: 0 }}
      elevation={3}
    >
      <BottomNavigation
        showLabels
        value={current}
        onChange={(_, newValue) => navigate(newValue)}
      >
        <BottomNavigationAction label="Карта" value="/" icon={<MapIcon />} />
        <BottomNavigationAction
          label="Добавить улов"
          value="/add-catch"
          icon={<AddLocationAltIcon />}
        />
        <BottomNavigationAction
          label="События"
          value="/events"
          icon={<EventIcon />}
        />
        <BottomNavigationAction
          label="Клубы"
          value="/clubs"
          icon={<GroupIcon />}
        />
        <BottomNavigationAction
          label="Чаты"
          value="/chats"
          icon={<ChatIcon />}
        />
        <BottomNavigationAction
          label="Уведомления"
          value="/notifications"
          icon={<NotificationsIcon />}
        />
      </BottomNavigation>
    </Paper>
  )
}
