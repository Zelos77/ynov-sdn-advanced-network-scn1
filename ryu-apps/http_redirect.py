#!/usr/bin/env python3
# Contrôleur SDN avancé avec :
# - Redirection HTTP
# - Détection de flux
# - Statistiques réseau

from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet, ethernet, ipv4, tcp
import time

class HttpRedirectController(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(HttpRedirectController, self).__init__(*args, **kwargs)
        
        # Configuration
        self.http_redirect_port = 2  # Port de redirection HTTP
        self.monitor_interval = 10  # Intervalle de monitoring (secondes)
        
        # Statistiques
        self.flow_stats = {}
        self.last_cleanup = time.time()

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        datapath = ev.msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # Installer une règle par défaut (envoyer au contrôleur)
        match = parser.OFPMatch()
        actions = [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER,
                                         ofproto.OFPCML_NO_BUFFER)]
        self.add_flow(datapath, 0, match, actions)

    def add_flow(self, datapath, priority, match, actions):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        # Construction du message FlowMod
        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,
                                            actions)]
        mod = parser.OFPFlowMod(datapath=datapath, priority=priority,
                               match=match, instructions=inst)
        datapath.send_msg(mod)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.match['in_port']

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)
        ip_pkt = pkt.get_protocol(ipv4.ipv4)
        tcp_pkt = pkt.get_protocol(tcp.tcp)

        # Logique de redirection HTTP
        if all([eth, ip_pkt, tcp_pkt]):
            self.logger.info(f"Packet IN - IP: {ip_pkt.src} -> {ip_pkt.dst} TCP:{tcp_pkt.src_port}->{tcp_pkt.dst_port}")

            # Détection HTTP (port 80 ou paquet GET)
            if tcp_pkt.dst_port == 80 or (tcp_pkt.dst_port == 80 and b'GET' in msg.data):
                self.logger.info("Détection trafic HTTP - Redirection vers port %s", self.http_redirect_port)
                
                # Règle de redirection
                match = parser.OFPMatch(
                    eth_type=0x0800,
                    ip_proto=6,  # TCP
                    tcp_dst=80,
                    in_port=in_port
                )
                actions = [parser.OFPActionOutput(self.http_redirect_port)]
                self.add_flow(datapath, 10, match, actions)

                # Envoyer le paquet immédiatement
                out = parser.OFPPacketOut(
                    datapath=datapath,
                    buffer_id=msg.buffer_id,
                    in_port=in_port,
                    actions=actions,
                    data=msg.data)
                datapath.send_msg(out)
                return

        # Règle par défaut : flood
        actions = [parser.OFPActionOutput(ofproto.OFPP_FLOOD)]
        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=in_port,
            actions=actions,
            data=msg.data)
        datapath.send_msg(out)

    @set_ev_cls(ofp_event.EventOFPFlowStatsReply, MAIN_DISPATCHER)
    def flow_stats_reply_handler(self, ev):
        body = ev.msg.body
        self.logger.info('Flow Stats:')
        for stat in body:
            self.logger.info(f'Match: {stat.match} Packets: {stat.packet_count} Bytes: {stat.byte_count}')
            self.flow_stats[stat.match] = (stat.packet_count, stat.byte_count)

        # Nettoyage périodique
        if time.time() - self.last_cleanup > self.monitor_interval:
            self.cleanup_flows(ev.msg.datapath)
            self.last_cleanup = time.time()

    def cleanup_flows(self, datapath):
        """Supprime les règles obsolètes"""
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        
        # Supprimer les règles avec plus de 60s d'inactivité
        match = parser.OFPMatch()
        mod = parser.OFPFlowMod(
            datapath=datapath,
            command=ofproto.OFPFC_DELETE,
            out_port=ofproto.OFPP_ANY,
            out_group=ofproto.OFPG_ANY,
            match=match,
            idle_timeout=60
        )
        datapath.send_msg(mod)
        self.logger.info("Nettoyage des règles de flux inactives")

if __name__ == '__main__':
    from ryu.cmd import manager
    manager.main()