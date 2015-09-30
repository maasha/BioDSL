# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'BioDSL/version'

Gem::Specification.new do |s|
  s.name              = 'BioDSL'
  s.version           = BioDSL::VERSION
  s.platform          = Gem::Platform::RUBY
  s.date              = Time.now.strftime('%F')
  s.summary           = 'BioDSL'
  s.description       = 'BioDSL is a Bioinformatics Domain Specific Language.'
  s.authors           = ['Martin A. Hansen']
  s.email             = 'mail@maasha.dk'
  s.rubyforge_project = 'BioDSL'
  s.homepage          = 'http://www.github.com/maasha/BioDSL'
  s.license           = 'GPL2'
  s.rubygems_version  = '2.0.0'
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").
    map { |f| File.basename(f) }
  s.extra_rdoc_files  = Dir['wiki/*.rdoc']
  s.require_paths     = ['lib']

  s.add_dependency('haml',           '>= 4.0.5')
  s.add_dependency('RubyInline',     '>= 3.12.2')
  s.add_dependency('narray',         '>= 0.6.0')
  s.add_dependency('mail',           '>= 2.5.4')
  s.add_dependency('msgpack',        '>= 0.5.8')
  s.add_dependency('gnuplotter',     '>= 1.0.2')
  s.add_dependency('parallel',       '>= 1.0.0')
  s.add_dependency('pqueue',         '>= 2.0.2')
  s.add_dependency('terminal-table', '>= 1.4.5')
  s.add_dependency('tilt',           '>= 2.0.1')
  s.add_development_dependency('bundler',   '>= 1.7.4')
  s.add_development_dependency('simplecov', '>= 0.9.2')
  s.add_development_dependency('mocha',     '>= 1.0.0')
end
